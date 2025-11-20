`timescale 1ns/1ns

module tb_pedagio;

// Declaração de sinais
reg ready;
reg reset;
reg clk;
reg [1:0] Eixos;                       // 2 bits (00 a 11) [4]
reg [3:0] Peso;                        // 4 bits (0 a 15t) [4]

// Saídas (Displays)
wire [6:0] S;                          // Display da categoria [1]
wire [6:0] S0;                         // Unidades [1]
wire [6:0] S1;                         // Dezenas [1]
wire [6:0] S2;                         // Centenas [1]
wire [6:0] S3;                         // Milhares [1]


// NSTANCIAÇÃO DO MÓDULO (DUT)

pedagio DUT (
    .ready(ready),
    .reset(reset),
    .clk(clk),
    .Eixos(Eixos),
    .Peso(Peso),
    .S(S),
    .S0(S0),
    .S1(S1),
    .S2(S2),
    .S3(S3)
);

// GERAÇÃO DO CLOCK (período de 10ns)

initial begin
    clk = 0;
    forever #5 clk = ~clk;             // Gera um clock com período de 10ns
end

// INICIALIZAÇÃO E MONITORAMENTO

initial begin
    $dumpfile("pedagio_sim.vcd");      // Arquivo de simulação de ondas
    $dumpvars(0, tb_pedagio);          // Salva todas as variáveis
    
    // Monitora o estado atual do sistema (útil para debug via console)
    $monitor("T=%0t | Rst=%b | Rdy=%b | Eixos=%b | Peso=%d | Categoria(S)=%b | Valor=%d | Total=d3:%d d2:%d d1:%d d0:%d",
             $time, reset, ready, Eixos, Peso, S, DUT.valor, DUT.d3, DUT.d2, DUT.d1, DUT.d0);
end

// BLOCO DE ESTÍMULO

initial begin
    // ESTADO INICIAL
    reset = 1;                         // Reseta o sistema
    ready = 0;
    Eixos = 2'b00;
    Peso = 4'd0;
    #10;
    
    // LIBERAÇÃO DO RESET
    reset = 0;
    #5;

    // TESTE 1: CATEGORIA 1 (Valor: 10)
    // Condição: Peso <= 7t (5t) e Eixos = 2 (00)
    // Total Esperado: 10

    $display("\n--- [T1] C1 (10) ---");
    Eixos = 2'b00;
    Peso = 4'd5;
    #5; 

    // Confirma Cobrança (Aciona Ready)
    ready = 1;
    #10;                               // Aguarda 1 ciclo de clock para a transição sequencial
    ready = 0;
    #5;

    // TESTE 2: CATEGORIA 3 (Valor: 50)
    // Condição: Peso > 12t (13t) e Eixos >= 4 (10)
    // Total Esperado: 10 + 50 = 60

    $display("\n--- [T2] C3 (50) ---");
    Eixos = 2'b10;
    Peso = 4'd13;
    #5;
    
    // Confirma Cobrança
    ready = 1;
    #10; 
    ready = 0;
    #5;
    
    // TESTE 3: CATEGORIA 2 (Valor: 25) - Teste de Carry BCD
    // Condição: Peso <= 12t (10t) e Eixos = 3 (01)
    // Total Esperado: 60 + 25 = 85

    $display("\n--- [T3] C2 (25) ---");
    Eixos = 2'b01;
    Peso = 4'd10;
    #5;

    // Confirma Cobrança
    ready = 1;
    #10; 
    ready = 0;
    #5;
    
    // TESTE 4: ERRO (Valor: 0)
    // Condição: Combinação não prevista (ex: Peso > 7t e Eixos = 2)
    // Total Esperado: 85 + 0 = 85

    $display("\n--- [T4] ERRO (0) ---");
    Eixos = 2'b00;
    Peso = 4'd8;                       // Peso 8t, 2 eixos (não é C1 nem C2/C3)
    #5;

    // Confirma Cobrança (Valor deve ser 0, Total permanece 85)
    ready = 1;
    #10; 
    ready = 0;
    #5;


    // TESTE 5: Forçando Carry de D1 para D2 (Soma 50)
    // Estado Atual: 85. Queremos: 85 + 50 = 135

    $display("\n--- [T5] C3 (50) - Forçando Carry de 8 para 13 ---");
    Eixos = 2'b11;                     // 5 ou mais eixos
    Peso = 4'd15;                      // 15t (C3)
    #5;
    
    ready = 1;
    #10; 
    ready = 0;
    #5;                                // Total deve ser 135 (d2=1, d1=3, d0=5)


    // TESTE 6: Forçando Carry de D0 e D1 na mesma operação (+25)
    // Estado Atual: 135. Queremos: 135 + 25 = 160
    // Teste CRÍTICO da lógica BCD complexa do 'case 8'd25'

    $display("\n--- [T6] C2 (25) - Forçando Carry em D0 e D1 ---");
    Eixos = 2'b01; 
    Peso = 4'd12;                      // C2 (25)
    #5;
    
    ready = 1;
    #10; 
    ready = 0;
    #5;                                // Total deve ser 160 (d2=1, d1=6, d0=0)
    

    // FIM DA SIMULAÇÃO

    #50;
    $finish; // Encerra a simulação

end

endmodule