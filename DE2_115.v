module DE2_115(

    //////////// LED //////////
    output [8:0] LEDG,
    output [17:0] LEDR,

    //////////// KEY //////////
    input [3:0] KEY,

    //////////// SW //////////
    input [17:0] SW,

    //////////// SEG7 //////////
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,
    output [6:0] HEX6,
    output [6:0] HEX7,

    //////////// GPIO //////////
    inout [35:0] GPIO
);
    wire [1:0] eixos = SW[1:0];
    wire [3:0] peso  = SW[5:2];

    reg [6:0] cat;
    reg [7:0] valor;

    always @(*) begin
        if (peso <= 7 && eixos == 0) begin
            cat   = 7'b1111001;  // "1"
            valor = 8'd10;
        end else if (peso <= 12 && eixos == 1) begin
            cat   = 7'b0100100;  // "2"
            valor = 8'd25;
        end else if (peso > 12 && eixos >= 2) begin
            cat   = 7'b0110000;  // "3"
            valor = 8'd50;
        end else begin
            cat   = 7'b0000110;  // "E"
            valor = 8'd0;
        end
    end

    assign HEX6 = cat;

    reg [3:0] d0=0, d1=0, d2=0, d3=0;  // Total acumulado
    reg [3:0] v0=0, v1=0;              // Valor do veículo

    // Variáveis temporárias
    reg [3:0] t0, t1, t2, t3;
    reg c1, c2, c3;
    integer x;

    always @(*) begin
        v0 = valor % 10;
        v1 = valor / 10;
    end

    always @(posedge KEY[0] or negedge KEY[2]) begin
        if (!KEY[2]) begin
            d0 <= 0; d1 <= 0; d2 <= 0; d3 <= 0;
        end else begin
            // Inicializa temporários
            t0 = d0; t1 = d1; t2 = d2; t3 = d3;
            c1 = 0; c2 = 0; c3 = 0;
            x  = valor;

            // Unidades
            t0 = t0 + (x % 10);
            if (t0 >= 10) begin t0 = t0 - 10; c1 = 1; end

            // Dezenas
            t1 = t1 + (x / 10) + c1;
            if (t1 >= 10) begin t1 = t1 - 10; c2 = 1; end

            // Centenas
            t2 = t2 + c2;
            if (t2 >= 10) begin t2 = t2 - 10; c3 = 1; end

            // Milhares
            t3 = t3 + c3;

            d0 <= t0; d1 <= t1; d2 <= t2; d3 <= t3;
        end
    end

    function [6:0] seg7;
        input [3:0] n;
        begin
            case(n)
                4'd0: seg7 = 7'b1000000;
                4'd1: seg7 = 7'b1111001;
                4'd2: seg7 = 7'b0100100;
                4'd3: seg7 = 7'b0110000;
                4'd4: seg7 = 7'b0011001;
                4'd5: seg7 = 7'b0010010;
                4'd6: seg7 = 7'b0000010;
                4'd7: seg7 = 7'b1111000;
                4'd8: seg7 = 7'b0000000;
                4'd9: seg7 = 7'b0010000;
                default: seg7 = 7'b1111111;
            endcase
        end
    endfunction

    assign HEX0 = seg7(d0);
    assign HEX1 = seg7(d1);
    assign HEX2 = seg7(d2);
    assign HEX3 = seg7(d3);

    assign HEX4 = seg7(v0); // Valor do veículo - unidades
    assign HEX5 = seg7(v1); // Valor do veículo - dezenas

    assign HEX7 = 7'b1111111; // desligado

endmodule
