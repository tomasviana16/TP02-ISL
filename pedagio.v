module pedagio (
// Entradas de Controle e Dados
input wire ready,                      // Sinal de confirmação de cobrança
input wire reset,                      // Sinal de reset assíncrono
input wire clk,                        // Clock para a lógica sequencial
input wire [1:0] Eixos,                // Número de eixos (2 a 5+)
input wire [3:0] Peso,                 // Peso total em toneladas (0 a 15t)

// Saídas de Display (7 segmentos)
output reg [6:0] S,                    // Saída do display da categoria
output reg [6:0] S0,                   // Display das unidades do valor total
output reg [6:0] S1,                   // Display das dezenas do valor total
output reg [6:0] S2,                   // Display das centenas do valor total
output reg [6:0] S3                    // Display dos milhares do valor total
);

// Sinais de classificação combinacional
wire Categoria1, Categoria2, Categoria3, peso_maior_12t, peso_menor_igual_12t;

// Determina limites de peso
assign peso_maior_12t = (Peso > 4'd12);
assign peso_menor_igual_12t = (Peso <= 4'd12);

// Lógica para determinar a Categoria 1 (peso <= 7t e eixos = 2)
assign Categoria1 = (Peso <= 4'd7) & (Eixos == 2'b00);

// Lógica para determinar a Categoria 2 (peso <= 12t e eixos = 3)
assign Categoria2 = peso_menor_igual_12t & (Eixos == 2'b01);

// Lógica para determinar a Categoria 3 (peso > 12t e eixos >= 4)
assign Categoria3 = peso_maior_12t & (Eixos >= 2'b10);

// Decodificador de Categoria
always @(*) begin
    S = 7'b0110000;                    // Padrão 'E' (Erro)

    if (Categoria1)
        S = 7'b1001111;                // Exibe '1'
    else if (Categoria2)
        S = 7'b0010010;                // Exibe '2'
    else if (Categoria3)
        S = 7'b0000110;                // Exibe '3'
end

// Valor da categoria (lógica combinacional)
reg [7:0] valor;

always @(*) begin
    valor = 8'd0;                      // Padrão para Erro
    if (Categoria1)
        valor = 8'd10;                 // Categoria 1: 10 unidades
    else if (Categoria2)
        valor = 8'd25;                 // Categoria 2: 25 unidades
    else if (Categoria3)
        valor = 8'd50;                 // Categoria 3: 50 unidades
end

// Registradores BCD para o valor total faturado
reg antigoReady;                       // Armazena estado anterior do READY
reg [3:0] d0;                          // Dígito das unidades
reg [3:0] d1;                          // Dígito das dezenas
reg [3:0] d2;                          // Dígito das centenas
reg [3:0] d3;                          // Dígito dos milhares

// Variáveis internas para cálculos BCD usando atribuições bloqueantes
reg [3:0] temp_d0, temp_d1, temp_d2;
reg carry_d0_to_d1, carry_d1_to_d2, carry_d2_to_d3;

// Lógica sequencial (Acumulação do total)
always @(posedge clk) begin

    if (reset) begin                   // Reset assíncrono
        d0 <= 0;
        d1 <= 0;
        d2 <= 0;
        d3 <= 0;
        antigoReady <= 0;
    end
    else begin
        
        // Inicializa as variáveis temporárias
        temp_d0 = d0;
        temp_d1 = d1;
        temp_d2 = d2;
        carry_d0_to_d1 = 1'b0;
        carry_d1_to_d2 = 1'b0;
        carry_d2_to_d3 = 1'b0;

        // Detecta a borda de subida do READY para realizar a cobrança
        if (antigoReady == 0 && ready == 1) begin 

            case (valor)

                // Soma 10 unidades
                8'd10: begin
                    temp_d1 = d1 + 1;                           // Adiciona 1 à dezena
                    carry_d1_to_d2 = (temp_d1 > 9);             // Verifica carry para d2
                    if (carry_d1_to_d2) temp_d1 = temp_d1 - 10;
                end

                // Soma 25 unidades
                8'd25: begin
                    // 1. Soma 5 às unidades (d0)
                    temp_d0 = d0 + 5;
                    carry_d0_to_d1 = (temp_d0 > 9);             // Verifica carry para d1
                    if (carry_d0_to_d1) temp_d0 = temp_d0 - 10;

                    // 2. Soma 2 às dezenas (d1) + o carry gerado por d0
                    temp_d1 = d1 + 2 + carry_d0_to_d1;
                    carry_d1_to_d2 = (temp_d1 > 9);             // Verifica carry para d2
                    if (carry_d1_to_d2) temp_d1 = temp_d1 - 10;
                end

                // Soma 50 unidades
                8'd50: begin
                    temp_d1 = d1 + 5;                           // Adiciona 5 à dezena
                    carry_d1_to_d2 = (temp_d1 > 9);             // Verifica carry para d2
                    if (carry_d1_to_d2) temp_d1 = temp_d1 - 10;
                end
                
            endcase
            
            // Propagação de Carries D2 e D3
            
            // Adiciona carry c1 (se houver) ao d2
            temp_d2 = d2 + carry_d1_to_d2;
            carry_d2_to_d3 = (temp_d2 > 9);                     // Verifica carry para d3
            if (carry_d2_to_d3) temp_d2 = temp_d2 - 10;

            // Aplica as atualizações de estado (Não Bloqueantes)
            
            d0 <= temp_d0;
            d1 <= temp_d1;
            d2 <= temp_d2;
            
            // Atualiza d3 (milhares) apenas se houver carry de d2
            if (carry_d2_to_d3)
                d3 <= d3 + 1;
            
        end 

        // Atualiza o valor anterior do READY para detecção de borda no próximo ciclo
        antigoReady <= ready;

    end

end

// Decodificadores BCD para 7 segmentos (d0: Unidades)
always @(*) begin
    case(d0)
    4'd0: S0 = 7'b1000000;
    4'd1: S0 = 7'b1111001;
    4'd2: S0 = 7'b0100100;
    4'd3: S0 = 7'b0110000;
    4'd4: S0 = 7'b0011001;
    4'd5: S0 = 7'b0010010;
    4'd6: S0 = 7'b0000010;
    4'd7: S0 = 7'b1111000;
    4'd8: S0 = 7'b0000000;
    4'd9: S0 = 7'b0010000;
    default: S0 = 7'b0110000; // Caso indefinido
    endcase

// Decodificadores BCD para 7 segmentos (d1: Dezenas)
    case(d1)
    4'd0: S1 = 7'b1000000;
    4'd1: S1 = 7'b1111001;
    4'd2: S1 = 7'b0100100;
    4'd3: S1 = 7'b0110000;
    4'd4: S1 = 7'b0011001;
    4'd5: S1 = 7'b0010010;
    4'd6: S1 = 7'b0000010;
    4'd7: S1 = 7'b1111000;
    4'd8: S1 = 7'b0000000;
    4'd9: S1 = 7'b0010000;
    default: S1 = 7'b0110000;
    endcase

// Decodificadores BCD para 7 segmentos (d2: Centenas)
    case(d2)
    4'd0: S2 = 7'b1000000;
    4'd1: S2 = 7'b1111001;
    4'd2: S2 = 7'b0100100;
    4'd3: S2 = 7'b0110000;
    4'd4: S2 = 7'b0011001;
    4'd5: S2 = 7'b0010010;
    4'd6: S2 = 7'b0000010;
    4'd7: S2 = 7'b1111000;
    4'd8: S2 = 7'b0000000;
    4'd9: S2 = 7'b0010000;
    default: S2 = 7'b0110000;
    endcase

// Decodificadores BCD para 7 segmentos (d3: Milhares)
    case(d3)
    4'd0: S3 = 7'b1000000;
    4'd1: S3 = 7'b1111001;
    4'd2: S3 = 7'b0100100;
    4'd3: S3 = 7'b0110000;
    4'd4: S3 = 7'b0011001;
    4'd5: S3 = 7'b0010010;
    4'd6: S3 = 7'b0000010;
    4'd7: S3 = 7'b1111000;
    4'd8: S3 = 7'b0000000;
    4'd9: S3 = 7'b0010000;
    default: S3 = 7'b0110000;
    endcase

end

endmodule