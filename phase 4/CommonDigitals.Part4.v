module FullAdder(InputA, FeedBack, C, Carry, Sum);
	input InputA;
	input FeedBack;
	input C;
	output Carry;
	output Sum;
	reg Carry;
	reg Sum;
 
	always @(*) 
	  begin
		// the equations below can be derived from the truth table of a full adder
		Sum= InputA^FeedBack^C;
		Carry= ((InputA^FeedBack)&C)|(InputA&FeedBack);  
	  end

endmodule

module SixteenBitFullAdder(InputA, FeedBack, C, Carry, Sum);
input [15:0] InputA;
input [15:0] FeedBack;
input C;

output Carry;
output [15:0] Sum;

wire [14:0] carryWires;

generate
    for(genvar i = 0; i < 16; i = i + 1) begin
        case(i)
            0: FullAdder FA0(InputA[i], FeedBack[i], C, carryWires[i], Sum[i]);
           15: FullAdder FA0(InputA[i], FeedBack[i], carryWires[i-1], Carry, Sum[i]);
           default: FullAdder FA0(InputA[i], FeedBack[i], carryWires[i-1], carryWires[i], Sum[i]);
        endcase
    end
endgenerate

endmodule

module SixteenBitAddSub(InputA, FeedBack, modeSUB, outputADDSUB, Carry, ADDerror);
input [15:0] InputA;
input [15:0] FeedBack;
input modeSUB;

output Carry;
output ADDerror;
output [31:0] outputADDSUB;

// XOR Interfaces: wires b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15
wire [15:0] xorWires;
// Carry Interfaces: wires c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16
wire [16:0] carryWires;

// Mode assigned to the initial carry [0/1]. Mode=0, Addition; Mode=1, Subtraction
assign carryWires[0]= modeSUB;

genvar i; 
generate
    for(i = 0; i < 16; i = i + 1) begin
        assign xorWires[i] = InputA[i] ^ modeSUB;
    end

    for(i = 0; i < 16; i = i + 1) begin
        FullAdder FA(FeedBack[i], xorWires[i], carryWires[i], carryWires[i+1], outputADDSUB[i]);
    end

    for(i = 31; i > 15; i = i - 1) begin
        assign outputADDSUB[i] = outputADDSUB[15];
    end
endgenerate

assign Carry = carryWires[16];
// overflow occurs if the value of the left most 2 bits have different values 
assign ADDerror = carryWires[16]^carryWires[15];

endmodule

module SixteenBitMultiplier(InputA, FeedBack, outputMUL);
input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputMUL;

reg [31:0] outputMUL;

// Local Variables
reg [15:0][15:0] Augends;
reg [15:0][15:0] Adends;

// range [16*16-1:0]
wire[16*16-1:0] Sums; 

// Carry Interfaces: wires c0,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15
wire [15:0] carryWires;

generate
    for(genvar i = 0; i < 16; i = i + 1) begin
        SixteenBitFullAdder SFA(Augends[i], Adends[i], 1'b0, carryWires[i], Sums[16*i+15:16*i]);    
    end
endgenerate

integer j;

always@(*) begin

    Augends[0]= { 1'b0, ({15{InputA[0]}}&FeedBack[15:1]) };

    //Augends[1]...Augends[15] is initialized inside the for loop
    for(j = 0; j < 15; j = j + 1) begin
        Augends[j+1] = { carryWires[0], Sums[(16*j+1)+:15] };
        Adends[j] = { {16{InputA[j+1]}}&FeedBack };
    end

    outputMUL[0] = InputA[0]&FeedBack[0];
    outputMUL[1+:15] = {
                        Sums[208], Sums[192], Sums[176], Sums[160], Sums[144], Sums[128], Sums[112],
                        Sums[96], Sums[80], Sums[64], Sums[48], Sums[32], Sums[16], Sums[0]
                    };
    outputMUL[15+:16] = Sums[239:224];
    outputMUL[31] = carryWires[14];

end

endmodule

module SixteenBitModulus(InputA,FeedBack,outputMOD,MODerror);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputMOD;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputMOD;

output MODerror;
reg MODerror;

integer i;

always @(InputA,FeedBack) begin
    outputMOD=FeedBack%InputA;

    for(i = 16; i < 32; i = i+1) begin
        outputMOD[i] = outputMOD[15];
    end

    MODerror=(InputA == 16'b0000000000000000);

end

endmodule

module SixteenBitDivision(InputA,FeedBack,outputDIV,DIVerror);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputDIV;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputDIV;

output DIVerror;
reg DIVerror;

integer i;

always @(InputA,FeedBack) begin
    outputDIV=FeedBack/InputA;

    for(i = 16; i < 32; i = i+1) begin
        outputDIV[i]= outputDIV[15];
    end

    DIVerror=(InputA == 16'b0000000000000000);

end

endmodule

module ANDER(InputA, FeedBack, outputAND);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputAND;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputAND;


always@(*) begin
    outputAND[15:0] = InputA&FeedBack;
    outputAND[31:16] = 16'b0000000000000000;
end

endmodule

module ORER(InputA, FeedBack, outputOR);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputOR;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputOR;

always@(*) begin
    outputOR[15:0] = InputA|FeedBack;
    outputOR[31:16] = 16'b0000000000000000;
end

endmodule

module XORER(InputA, FeedBack, outputXOR);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputXOR;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputXOR;

always@(*) begin
    outputXOR[15:0] = InputA^FeedBack;
    outputXOR[31:16] = 16'b0000000000000000;
end

endmodule

module NANDER(InputA, FeedBack, outputNAND);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputNAND;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputNAND;

always@(*) begin
    outputNAND[15:0] = ~(InputA&FeedBack);
    outputNAND[31:16] = 16'b0000000000000000;
end

endmodule

module NORER(InputA, FeedBack, outputNOR);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputNOR;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputNOR;

always@(*) begin
    outputNOR[15:0] = ~(InputA|FeedBack);
    outputNOR[31:16] = 16'b0000000000000000;
end

endmodule

module XNORER(InputA, FeedBack, outputXNOR);

input [15:0] InputA;
input [15:0] FeedBack;
output [31:0] outputXNOR;

wire [15:0] InputA;
wire [15:0] FeedBack;
reg [31:0] outputXNOR;

always@(*) begin
    outputXNOR[15:0] = ~(InputA^FeedBack);
    outputXNOR[31:16] = 16'b0000000000000000;
end

endmodule

module NOTER(Current, outputNOT);

input [31:0] Current;
output [31:0] outputNOT;

wire [31:0] Current;
reg [31:0] outputNOT;

always@(*) begin
    outputNOT = ~(Current);
end

endmodule

module DFF(Clk, In,Out);
	input   Clk;
	input   In;
	output  Out;
	reg     Out;

    // posedge means the transition from 0 to 1
	always @(posedge Clk)
	Out = In;
endmodule

module Mux16x1(channels, onehot, selected);
input [15:0][31:0] channels; // 16 channels where each of the channels contain 32 bit number
input [15:0] onehot;
output[31:0] selected;

    // A x 1 = A or A x 0 = 0
	assign selected =   ({32{onehot[15]}} & channels[15]) | 
                        ({32{onehot[14]}} & channels[14]) |
			            ({32{onehot[13]}} & channels[13]) |
			            ({32{onehot[12]}} & channels[12]) |
			            ({32{onehot[11]}} & channels[11]) |
			            ({32{onehot[10]}} & channels[10]) |
			            ({32{onehot[ 9]}} & channels[ 9]) | 
			            ({32{onehot[ 8]}} & channels[ 8]) |
			            ({32{onehot[ 7]}} & channels[ 7]) |
			            ({32{onehot[ 6]}} & channels[ 6]) |
			            ({32{onehot[ 5]}} & channels[ 5]) |  
			            ({32{onehot[ 4]}} & channels[ 4]) |  
			            ({32{onehot[ 3]}} & channels[ 3]) |  
			            ({32{onehot[ 2]}} & channels[ 2]) |  
                        ({32{onehot[ 1]}} & channels[ 1]) |  
                        ({32{onehot[ 0]}} & channels[ 0]) ;

endmodule

module Dec4x16(Opcode, onehot);

	input [3:0] Opcode; // opcode
	output [15:0] onehot; // 16 bit hot select being fed into a 16:1 MUX
	
	assign onehot[ 0]=~Opcode[3]&~Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[ 1]=~Opcode[3]&~Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[ 2]=~Opcode[3]&~Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[ 3]=~Opcode[3]&~Opcode[2]& Opcode[1]& Opcode[0];
	assign onehot[ 4]=~Opcode[3]& Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[ 5]=~Opcode[3]& Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[ 6]=~Opcode[3]& Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[ 7]=~Opcode[3]& Opcode[2]& Opcode[1]& Opcode[0];
	assign onehot[ 8]= Opcode[3]&~Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[ 9]= Opcode[3]&~Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[10]= Opcode[3]&~Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[11]= Opcode[3]&~Opcode[2]& Opcode[1]& Opcode[0];
	assign onehot[12]= Opcode[3]& Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[13]= Opcode[3]& Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[14]= Opcode[3]& Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[15]= Opcode[3]& Opcode[2]& Opcode[1]& Opcode[0];

endmodule

module breadboard(Clk, InputA, Result, OpCode, Error);

input [15:0] InputA;
input [3:0]  OpCode;

wire [15:0] InputA;
wire [3:0]  OpCode;

output [1:0] Error;
reg [1:0] Error;

output [31:0] Result;
reg [31:0] Result;

// Control
wire [15:0][31:0] channels;
wire [15:0] onehot;
wire [31:0] selected;
wire [31:0] unknown;

// Memory Register Related
input Clk; 
wire Clk;
wire [31:0] Current;
reg [15:0] FeedBack;
reg [31:0] Next;

Dec4x16 decoder(OpCode, onehot);
Mux16x1 multiplexer(channels, onehot, selected);

// declare wires carrying the results of each of the arithmetic operations
wire [31:0] outputADDSUB;
wire [31:0] outputMUL;
wire [31:0] outputDIV;
wire [31:0] outputMOD;

// declare wires carrying the results of each of the logical operations
wire [31:0] outputAND;
wire [31:0] outputOR;
wire [31:0] outputXOR;
wire [31:0] outputNAND;
wire [31:0] outputNOR;
wire [31:0] outputXNOR;
wire [31:0] outputNOT;

// declare wires carrying error codes
wire ADDerror;
wire DIVerror;
wire MODerror;

// arithmetic operation modules 
SixteenBitAddSub add(InputA, FeedBack, modeSUB, outputADDSUB, Carry, ADDerror);
SixteenBitMultiplier mult(InputA, FeedBack, outputMUL);
SixteenBitDivision div(InputA, FeedBack, outputDIV, DIVerror);
SixteenBitModulus mod(InputA, FeedBack, outputMOD, MODerror); 

// logical operation modules
ANDER ander(InputA, FeedBack, outputAND);
ORER orer(InputA, FeedBack, outputOR);
XORER xorer(InputA, FeedBack, outputXOR);
NANDER nander(InputA, FeedBack, outputNAND);
NORER norer(InputA, FeedBack, outputNOR);
XNORER xnorer(InputA, FeedBack, outputXNOR);
// NOTE: The cohort decided to invert the current value of the accumulator, not the given input.
NOTER noter(Current, outputNOT);

// 32-bit Memory Register
DFF ACCUMULATOR [31:0] (Clk, Next, Current);

// Error Reporting
reg modeADD;
reg modeSUB;
reg modeDIV;
reg modeMOD;

// Connect the MUX to the OpCodes
assign channels[ 0]=Current;
assign channels[ 1]=0; // RESET
assign channels[ 2]= {32{1'b1}}; // PRESET
assign channels[ 3]=unknown;
assign channels[ 4]=outputADDSUB;
assign channels[ 5]=outputADDSUB;
assign channels[ 6]=outputMUL;
assign channels[ 7]=outputDIV;
assign channels[ 8]=outputMOD;
assign channels[ 9]=outputAND;
assign channels[10]=outputOR;
assign channels[11]=outputXOR;
assign channels[12]=outputNAND;
assign channels[13]=outputNOR;
assign channels[14]=outputXNOR;
assign channels[15]=outputNOT;

always@(*)
begin
    // feedback represents the 16-bit number provided by the memory register [ACC]
    FeedBack = Current[15:0];

    modeADD=~OpCode[3]& OpCode[2]&~OpCode[1]&~OpCode[0];//0100, Channel 4
    modeSUB=~OpCode[3]& OpCode[2]&~OpCode[1]& OpCode[0];//0101, Channel 5
    modeDIV=~OpCode[3]& OpCode[2]& OpCode[1]& OpCode[0];//0111, Channel 7
    modeMOD= OpCode[3]&~OpCode[2]&~OpCode[1]&~OpCode[0];//1000, Channel 8
    // connect the output line of the memory register to the register containing the final output for given operation
    assign Result = Current;
    // connect the output line of the multiplexer to the memory register containing the selected output
    assign Next = selected;
    //Only show overflow if in add or subtract operation
    Error[0]=ADDerror&(modeADD|modeSUB);
    //only show divide by zero if in division or modulus operation
    Error[1]=(DIVerror|MODerror)&(modeDIV|modeMOD);

end

endmodule

module testbench();

    // Local Variables
    reg  [15:0] InputA;
    reg  [3:0] OpCode;
    wire [31:0] Result;
    wire [1:0] Error;

    reg [15:0] radius;
    reg [31:0] hold;
    reg [31:0] whole;
    reg [31:0] fraction;

    // Todo: change the clk to Clk whenever creating the stimulus tread
    reg clk;

    // create breadboard
    breadboard bb32(clk, InputA, Result, OpCode, Error);

    // TODO: Create a clock thread

    // TODO: Create a stimulus thread for demonstrating the calculation of 10 unique equations
    initial begin

	radius=5;

	$display("Reset");
	clk=0;InputA=16'd0  ; OpCode=4'b0001;#5;//Reset 
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error); 
	clk=1;InputA=16'd0  ; OpCode=4'b0001;#5;//Reset 
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);

	$display("--------------------------");
	$display("Add 2");
	clk=0;InputA=16'd2  ; OpCode=4'b0100;#5;//Add 2 
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=16'd2  ; OpCode=4'b0100;#5;//Add 2 
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);

	$display("--------------------------");
	$display("Multiply by Radius");
	clk=0;InputA=radius ; OpCode=4'b0110;#5;//Multiply by R 
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=radius ; OpCode=4'b0110;#5;//Multiply by R 
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);

	$display("--------------------------");
	$display("Multiply by 314");
	clk=0;InputA=16'd314; OpCode=4'b0110;#5;//Multiply by 314
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=16'd314; OpCode=4'b0110;#5;//Multiply by 314
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	
	hold=Result;
	
	$display("--------------------------");
	$display("Divide by 100");
	clk=0;InputA=16'd100;	OpCode=4'b0111;#5;
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=16'd100;	OpCode=4'b0111;#5;
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	
	whole=Result;#5;//Divide by 100
	
	$display("--------------------------");
	$display("Reset");
   	clk=0;InputA=16'd0;	OpCode=4'b0001;#5;//Reset
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=16'd0;	OpCode=4'b0001;#5;//Reset
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	
	$display("--------------------------");
	$display("Add back temp value");
 	clk=0;InputA=hold   ; OpCode=4'b0100;#5;//Add Temp back
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=hold   ; OpCode=4'b0100;#5;//Add Temp back
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);

    $display("--------------------------");
	$display("Subtract 100");
 	clk=0;InputA=16'd100   ; OpCode=4'b0101;#5;//Substract 100
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=16'd100   ; OpCode=4'b0101;#5;//Substract 100
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	
	$display("--------------------------");
	$display("Modulus by 100");
	clk=0;InputA=16'd100;	OpCode=4'b1000;#5;
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);
	clk=1;InputA=16'd100;	OpCode=4'b1000;#5;
	$display("%b|%d|%b|%d|%b",clk,InputA,OpCode,Result,Error);

	fraction=Result;
	
	$display("==========================");
	$display("Circumference of a circle with radius %2d is %3d.%-2d.",radius,whole,fraction);
	$finish;
	end
endmodule