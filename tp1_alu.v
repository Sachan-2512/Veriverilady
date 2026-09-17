`timescale 1ns / 1ps

module tp1_alu#(
    parameter NB_DATA = 8,
    parameter NB_OPCODE = 6
  )(
  input wire [NB_DATA - 1:0] A_data,
  input wire [NB_DATA - 1:0] B_data,
  input wire [NB_OPCODE - 1:0] OP_data,
  output reg [NB_DATA - 1:0] result
);
  always@(*) begin
    result = 0;
    
    if (OP_data == 6'b100000) // ADD
      result = A_data + B_data;
    
    else if (OP_data == 6'b100010) // SUB
      result = A_data - B_data;
     
    else if (OP_data == 6'b100100) // AND
      result = A_data & B_data;
    
    else if (OP_data == 6'b100101) // OR
      result = A_data | B_data;
    
    else if (OP_data == 6'b100110) // XOR
      result = A_data ^ B_data;
    
    else if (OP_data == 6'b000011) // SRA
      result = $signed(A_data) >>> B_data;
    
    else if (OP_data == 6'b000010)
      result = A_data >> B_data; // SRL
    
    else if (OP_data == 6'b100111)
      result = ~(A_data | B_data); // NOR
    
  end
  
endmodule