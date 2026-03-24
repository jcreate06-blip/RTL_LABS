`timescale 1ns / 1ps

module seg_decoder(
    input logic [3:0] x,
    output logic [7:0] seg 
    );
     
    logic A, B, C, D;
    
    assign A = x[3];
    assign B = x[2];
    assign C = x[1];
    assign D = x[0];    
    
    // Segment a
    assign seg[0] = ~((~B & ~D) |(B & C)| (A &~D) | (~A & C)|(A & ~B & ~C)|(~A & B & D));
    // Segment b
    assign seg[1] = ~((~B & ~D) | (~B & ~C) | (~A & C & D) | (A & ~C & D) | (~A & ~C & ~D));
    // Segment c 
    assign seg[2] = ~((A & ~B) | (~A & B) | (~A & D) | (~C & D) | (~A & ~C));
    // Segment d
    assign seg[3] = ~((B & C & ~D) | (A & B & ~C) | (~B & ~C & ~D) | (B & ~C & D) | (~A & ~B & C) | (~B & C & D));
    // Segment e
    assign seg[4] = ~((~B & ~D) | (C & ~D) | (A & B) | (A & C));
    // Segment f
    assign seg[5] = ~((A & ~B) | (A & C) | (B & ~D) | (~C & ~D) | (~A & B & ~C));
    // Segment g
    assign seg[6] = ~((C & ~D) | (A & ~B) | (~B & C) | (A & D) | (~A & B & ~C));
    // Decimal point (usually off)
    assign seg[7] = 1'b1;

endmodule