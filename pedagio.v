module pedagio_terasic(
    input  wire        CLOCK_50,
    input  wire [9:0]  SW,
    input  wire [3:0]  KEY,      

    output reg  [6:0]  HEX7,
    output reg  [6:0]  HEX0,
    output reg  [6:0]  HEX1,
    output reg  [6:0]  HEX2,
    output reg  [6:0]  HEX3,
    output reg  [17:0] LEDR
);

    //=======================================================
    // Entrada mapeada
    //=======================================================

    wire [1:0] Eixos = SW[1:0];
    wire [3:0] Peso  = SW[4:1];
    wire       READY = SW[8];
    wire       nRESET = KEY[0];   // Reset ativo-baixo

    //=======================================================
    // Classificação
    //=======================================================
    
    wire Categoria1 = (Peso <= 7)  && (Eixos == 2'b00);
    wire Categoria2 = (Peso <= 12) && (Eixos == 2'b01);
    wire Categoria3 = (Peso >  12) && (Eixos >= 2'b10);

    reg [7:0] valor;

    always @(*) begin
        valor = 0;
        if (Categoria1) valor = 10;
        else if (Categoria2) valor = 25;
        else if (Categoria3) valor = 50;
    end

    //=======================================================
    // Acumulador BCD (d0..d3)
    //=======================================================

    reg [3:0] d0, d1, d2, d3;
    reg ready_reg;
    wire ready_rising = !ready_reg && READY;

    reg [3:0] tmp_d0, tmp_d1, tmp_d2, tmp_d3;
    reg c0, c1, c2;

    always @(posedge CLOCK_50 or negedge nRESET) begin
        if (!nRESET) begin
            d0 <= 0; d1 <= 0; d2 <= 0; d3 <= 0;
            ready_reg <= 0;
        end else begin
            ready_reg <= READY;

            if (ready_rising) begin
                tmp_d0 = d0;
                tmp_d1 = d1;
                tmp_d2 = d2;
                tmp_d3 = d3;
                c0 = 0; c1 = 0; c2 = 0;

                case (valor)
                    10: begin
                        tmp_d1 = d1 + 1;
                        if (tmp_d1 > 9) begin tmp_d1 -= 10; c1 = 1; end
                    end

                    25: begin
                        tmp_d0 = d0 + 5;
                        if (tmp_d0 > 9) begin tmp_d0 -= 10; c0 = 1; end

                        tmp_d1 = d1 + 2 + c0;
                        if (tmp_d1 > 9) begin tmp_d1 -= 10; c1 = 1; end
                    end

                    50: begin
                        tmp_d1 = d1 + 5;
                        if (tmp_d1 > 9) begin tmp_d1 -= 10; c1 = 1; end
                    end
                endcase

                tmp_d2 = d2 + c1;
                if (tmp_d2 > 9) begin tmp_d2 -= 10; c2 = 1; end

                tmp_d3 = d3 + c2;

                d0 <= tmp_d0;
                d1 <= tmp_d1;
                d2 <= tmp_d2;
                d3 <= tmp_d3;
            end
        end
    end

    //=======================================================
    // Debug LEDs
    //=======================================================
    always @(*) begin
        LEDR[0] = Eixos[0];
        LEDR[1] = Eixos[1];
        LEDR[2] = Peso[0];
        LEDR[3] = Peso[1];
        LEDR[4] = Peso[2];
        LEDR[5] = Peso[3];
        LEDR[8] = READY;
        LEDR[17:9] = 0;
    end

    //=======================================================
    // Categoria no HEX7
    //=======================================================

    localparam SEG_0 = 7'b1000000;
    localparam SEG_1 = 7'b1111001;
    localparam SEG_2 = 7'b0100100;
    localparam SEG_3 = 7'b0110000;
    localparam SEG_4 = 7'b0011001;
    localparam SEG_5 = 7'b0010010;
    localparam SEG_6 = 7'b0000010;
    localparam SEG_7 = 7'b1111000;
    localparam SEG_8 = 7'b0000000;
    localparam SEG_9 = 7'b0010000;
    localparam SEG_E = 7'b0110000;

    always @(*) begin
        if      (Categoria1) HEX7 = SEG_1;
        else if (Categoria2) HEX7 = SEG_2;
        else if (Categoria3) HEX7 = SEG_3;
        else HEX7 = SEG_E;
    end

    //=======================================================
    // HEX0–HEX3 BCD
    //=======================================================

    task decode;
        input [3:0] d;
        output reg [6:0] h;
        begin
            case (d)
                0: h = SEG_0;
                1: h = SEG_1;
                2: h = SEG_2;
                3: h = SEG_3;
                4: h = SEG_4;
                5: h = SEG_5;
                6: h = SEG_6;
                7: h = SEG_7;
                8: h = SEG_8;
                9: h = SEG_9;
                default: h = SEG_E;
            endcase
        end
    endtask

    always @(*) begin
        decode(d0, HEX0);
        decode(d1, HEX1);
        decode(d2, HEX2);
        decode(d3, HEX3);
    end

endmodule