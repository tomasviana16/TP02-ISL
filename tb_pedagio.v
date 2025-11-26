`timescale 1ns/1ns
`include "DE2_115.v"
module tb_pedagio;

    // Entradas
    reg [3:0] KEY;
    reg [17:0] SW;

    // Saídas
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

    DE2_115 DUT (
        .KEY(KEY),
        .SW(SW),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .HEX6(HEX6),
        .HEX7(HEX7)
    );

    // Clock 
    initial begin
        KEY = 4'b0000;
        SW = 18'b0;
        #5;
    end

    // Função para simular pressionamento de KEY[0]
    task pulse_key0;
    begin
        KEY[0] = 1; #10;
        KEY[0] = 0; #5;
    end
    endtask

    // Função para resetar (KEY[2])
    task reset_total;
    begin
        KEY[2] = 0; #10;
        KEY[2] = 1; #5;
    end
    endtask

    initial begin
        $dumpfile("pedagio_sim.vcd");
        $dumpvars(0, tb_pedagio);

        $monitor("T=%0t | KEY=%b | SW(E,P)=%b,%d | HEX6(Cat)=%b | HEX5,HEX4(Valor)=%b,%b | HEX3..0(Total)=%b,%b,%b,%b",
                 $time, KEY, SW[1:0], SW[5:2], HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
    end

    initial begin
        // Reset inicial
        reset_total();

        // TESTE 1: Categoria 1, Valor 10
        $display("\n--- [T1] C1 (10) ---");
        SW[1:0] = 2'b00; // Eixos
        SW[5:2] = 4'd5;  // Peso
        #5;
        pulse_key0();
        #10;

        // TESTE 2: Categoria 3, Valor 50
        $display("\n--- [T2] C3 (50) ---");
        SW[1:0] = 2'b10; // Eixos
        SW[5:2] = 4'd13; // Peso
        #5;
        pulse_key0();
        #10;

        // TESTE 3: Categoria 2, Valor 25
        $display("\n--- [T3] C2 (25) ---");
        SW[1:0] = 2'b01; 
        SW[5:2] = 4'd10;
        #5;
        pulse_key0();
        #10;

        // TESTE 4: Erro (Valor 0)
        $display("\n--- [T4] ERRO (0) ---");
        SW[1:0] = 2'b00;
        SW[5:2] = 4'd8;
        #5;
        pulse_key0();
        #10;

        // TESTE 5: Categoria 3
        $display("\n--- [T5] C3 (50) ---");
        SW[1:0] = 2'b11;
        SW[5:2] = 4'd15;
        #5;
        pulse_key0();
        #10;

        // TESTE 6: Categoria 2
        $display("\n--- [T6] C2 (25) ---");
        SW[1:0] = 2'b01;
        SW[5:2] = 4'd12;
        #5;
        pulse_key0();
        #10;

        // Finaliza simulação
        #50;
        $finish;
    end

endmodule