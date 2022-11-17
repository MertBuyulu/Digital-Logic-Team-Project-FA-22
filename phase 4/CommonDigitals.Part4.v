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

    // Local variables
    reg  [15:0] InputA;
    reg  [3:0] OpCode;
    wire [31:0] Result;
    wire [1:0] Error;

	reg Clk;

	// Local variables to display at the end of each calculation
    reg [31:0] whole;
    reg [31:0] fraction;

	// A local varible to store the result of the calculation before its partition to its whole and fraction parts
	reg [31:0] temp, temp_2, temp_3, temp_4, temp_frac;

	// Local variables need for all of the equations 
	// NOTE: a local variable can be used more than one calculation, if needed.
	reg [15:0] numerator, reminder;
	reg [15:0] base1, base2; 
	reg [15:0] height;
	reg [15:0] breadth;
	reg [15:0] radius;
	reg [15:0] timeI, timeF;
	reg [15:0] velocityI, velocityF;
	reg [15:0] slant, apothem;

    // create breadboard
    breadboard bb32(Clk, InputA, Result, OpCode, Error);

	// Clock Thread
    initial begin
		// set initial value of the clock signal to be 0.
		Clk = 1'b0;
        forever
			// #5 is the time for clock signal to go from 0 to 1 and vice-versa.
			#5 Clk = ~Clk; 
	end
	
	// Display Single Step Thread
	initial begin
		#13;
		$display("--------------------------");
		forever
        	begin
				
				// Note: the opcodes for logical operations are not included since they 
				// are not used when performing calculations of the selected formulas.
				case (OpCode)
					0: $display("No-op");
					1: $display("Reset");
					4:  if (InputA != temp & InputA != temp_2 & InputA != temp_3)
							$display("Add %2d", InputA);
						else
							begin 
								if(InputA == temp)
									$display("Add temp value (%2d) back", InputA);
								else 
									begin
										if (InputA == temp_2)
											$display("Add temp 2 value (%2d) back", InputA);
										else 
											$display("Add temp 3 value (%2d) back", InputA);
									end
							end
					5: $display("Subtract %2d", InputA);
					6: if (InputA != temp & InputA != temp_2 & InputA != temp_3)
							$display("Multiply by %1d", InputA);
						else
							begin 
								if(InputA == temp)
									$display("Multiply by temp value (%1d)", InputA);
								else 
									begin
										if (InputA == temp_2)
											$display("Multiply by temp 2 value (%1d)", InputA);
										else 
											$display("Multiply by temp 3 value (%1d)", InputA);
									end
							end
					7: 	begin
							$display("Divide by %1d", InputA);
							// reset reminder
							reminder = 0;
							if(numerator % 2 != 0 | numerator % 3 != 0)
								$display("Warning: division operation will result in a reminder of one... It will be handled in the latter steps.");
								// set reminder
								reminder = 1;
								// reset numerator
								numerator = 0;

						end

					8: $display("Modulus %2d", InputA);
				endcase;

				// display the content of the system before and after the clock ticks
				$display("%b|%d|%b|%d|%b",Clk,InputA,OpCode,Result,Error);
				#5;
				$display("%b|%d|%b|%d|%b",Clk,InputA,OpCode,Result,Error);
				#5
				$display("--------------------------");
			end

	end
	
   	// Stimulus Thread
    initial begin

		$display("-------------- Welcome to the Program ------------------------\n");
		$display("The program will calculate the following 10 equations:");
		$display("--------------------------------------------------------------");
		$display("1. Area of a Trapezoid: ((a + b)/2) * h\n  - a = base 1\n  - b = base 2\n  - h = height  ");
		$display("--------------------------------------------------------------");
		$display("2. Volume of a Pentagonal Prism: (5/2) * abh\n  - a = length of the apothem\n  - b = base length of the prism\n  - h = height of the prism");
		$display("--------------------------------------------------------------");
		$display("3. Perimeter of a Rectange: 2a+2b = 2(a + b)\n  - a = length of the shorter side\n  - b = length of the longer side");
		$display("--------------------------------------------------------------");
		$display("4. Surface Area of a Sphere: 4 * Pi * r^2\n  - r  = radius\n  - Pi = taken as 3.14");
		$display("--------------------------------------------------------------");;
		$display("5. Area of a Circle: Pi * r^2\n  - r  = radius\n  - Pi = taken as 3.14");
		$display("--------------------------------------------------------------");
		$display("6. Volume of a Cyclinder: Pi * r^2 * h\n  - r  = radius\n  - Pi = taken as 3.14\n  - h  = height of the cylinder");
		$display("--------------------------------------------------------------");
		$display("7. Average Acceleration of an Object: ((Vf - Vi) / (tf - ti))\n  - Vf = final velocity\n  - Vi = initial velocity\n  - Tf = final time\n  - Ti = start time");
		$display("--------------------------------------------------------------");;
		$display("8. Surface Area of a Pyramid: (1/2) * PI + B\n  - P = base perimeter of the pyramid\n  - I = slant height of the pyramid\n  - B = the base area of the pyramid");
		$display("--------------------------------------------------------------");
		$display("9. Surface Area of a Cuboid: 2(lb + bh + hl)\n  - h = height of the cuboid\n  - b = breadth of the cuboid\n  - l = length of the cuboid");
		$display("--------------------------------------------------------------");
		$display("10. Volume of a Cone: Pi * r * (h/3)\n  - Pi = taken as 3.14\n  - r  = radius\n  - h  = height of the cone");
		$display("--------------------------------------------------------------\n");
		$display("The program has started.\n");	
		#10;

		// EQUATION 1 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		base1 = 14;
		base2 = 13;
		height = 23;

		$display("Calculate: The area of a trapezoid with bases %2d, %2d respectively and height %2d.\n",base1,base2,height);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=base1; OpCode=4'b0100;
		#10;
		InputA=base2; OpCode=4'b0100;
		#10;
		InputA=height; OpCode=4'b0110;
		#10;
		InputA=100; OpCode=4'b0110;
		#10;
		InputA=2; OpCode=4'b0111;
		#10;
		temp=Result;
		InputA=100; OpCode=4'b0111;
		#10;
		whole=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		fraction=Result;

		$display("---------------------------\n\nResult: Area of a trapezoid with bases %2d, %2d respectively and height %2d is %3d.%-1d.\n",base1,base2,height,whole,fraction);

		// EQUATION 2 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		base1 = 23;
		apothem = 12;
		height = 26;

		$display("Calculate: The volume of a pentagonal prism with a base edge %1d, apothem %1d, and height %1d.\n", base1, apothem, height);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=apothem; OpCode=4'b0100;
		#10;
		InputA=base1; OpCode=4'b0110;
		#10;
		InputA=height; OpCode=4'b0110;
		#10;
		InputA=5; OpCode=4'b0110;
		#10;
		InputA=2; OpCode=4'b0111;
		#10;
		whole=Result;

		$display("---------------------------\n\nResult: Volume of a pentagonal prism with a base edge %2d, apothem %2d, and height %2d is %3d.\n", base1, apothem, height, whole);

		// EQUATION 3 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		base1 = 23;
		base2 = 45;

		$display("Calculate: The perimeter of a rectangle with a length %2d, and width %2d.\n", base1, base2);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=base1; OpCode=4'b0100;
		#10;
		InputA=base2; OpCode=4'b0100;
		#10;
		InputA=2; OpCode=4'b0110;
		#10;
		whole=Result;

		$display("---------------------------\n\nResult: Perimeter of a rectangle with a length %2d, and width %2d is %3d.\n", base1, base2, whole);

		// EQUATION 4 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		radius = 19;

		$display("Calculate: The surface area of a sphere with radius %1d.\n", radius);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate 4 * radius * radius
		InputA=radius; OpCode=4'b0100;
		#10;
		InputA=radius; OpCode=4'b0110;
		#10;
		InputA=4; OpCode=4'b0110;
		#10;
		temp = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate 3 x the rest
		InputA=3; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		temp_2 = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate .14 x the rest
		InputA=14; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		temp_3 = Result;
		// calculate the whole and fraction portions of temp_3
		InputA=100; OpCode=4'b0111;
		#10;
		temp = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		whole = temp + temp_2;
		fraction = Result;

		$display("---------------------------\n\nResult: Surface area of a sphere with radius %1d is %3d.%-1d.\n", radius, whole, fraction);
		

		// EQUATION 5 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		radius = 29;

		$display("Calculate: The area of a circle with with radius %1d.\n", radius);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate radius * radius
		InputA=radius; OpCode=4'b0100;
		#10;
		InputA=radius; OpCode=4'b0110;
		#10;
		temp = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate 3 x the rest
		InputA=3; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		temp_2 = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate .14 x the rest
		InputA=14; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		temp_3 = Result;
		// calculate the whole and fraction portions of temp_3
		InputA=100; OpCode=4'b0111;
		#10;
		temp = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		whole = temp + temp_2;
		fraction = Result;

		$display("---------------------------\n\nResult: Area of a circle with with radius %1d is %3d.%-1d.\n", radius, whole, fraction);

		// EQUATION 6 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		radius = 8;
		height = 6;

		$display("Calculate: The volume of a cylinder with with radius %1d and height %1d.\n", radius, height);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate height * radius * radius
		InputA=radius; OpCode=4'b0100;
		#10;
		InputA=radius; OpCode=4'b0110;
		#10;
		InputA=height; OpCode=4'b0110;
		#10;
		temp = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate 3 x the rest
		InputA=3; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		temp_2 = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate .14 x the rest
		InputA=14; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		temp_3 = Result;
		// calculate the whole and fraction portions of temp_3
		InputA=100; OpCode=4'b0111;
		#10;
		temp = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		whole = temp + temp_2;
		fraction = Result;

		$display("---------------------------\n\nResult: Volume of a cylinder with with radius %1d and height %1d is %3d.%-1d.\n", radius, height, whole, fraction);

		// EQUATION 7 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		velocityI = 120;
		velocityF = 312;
		timeI = 10;
		timeF = 43;

		$display("Calculate: The average acceleration of an object with initial and final velocities %3d, %3d respectively and time displacement %2d.\n", velocityI, velocityF, timeF-timeI);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=velocityF; OpCode=4'b0100;
		#10;
		InputA=velocityI; OpCode=4'b0101;
		#10;
		temp=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=timeF; OpCode=4'b0100;
		#10;
		InputA=timeI; OpCode=4'b0101;
		#10;
		temp_2=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b0110;
		#10;
		InputA=temp_2; OpCode=4'b0111;
		#10;
		temp=Result;
		InputA=100; OpCode=4'b0111;
		#10;
		whole=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;

		fraction=Result;

		$display("---------------------------\n\nResult: Average acceleration of an object with initial and final velocities %3d, %3d respectively and time displacement %2d is %1d.%-2d.\n", velocityI, velocityF, timeF-timeI, whole, fraction);

		// EQUATION 8 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		slant = 17;
		base1 = 39;

		$display("Calculate: The surface area of a regular pyramid with a base edge %2d and slant height %2d.\n", base1, slant);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate PI (4 * base1)I first
		InputA=base1; OpCode=4'b0100;
		#10;
		InputA=4; OpCode=4'b0110;
		#10;
		InputA=slant; OpCode=4'b0110;
		#10;
		// store the value of PI in temp
		temp=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate B (base1^2)
		InputA=base1; OpCode=4'b0100;
		#10;
		InputA=base1; OpCode=4'b0110;
		#10;
		temp_2=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate PI + B
		InputA=temp; OpCode=4'b0100;
		#10;
		// calculate (1/2) * PI + B
		InputA=temp_2; OpCode=4'b0100;
		#10;
		numerator= Result;
		InputA=2; OpCode=4'b0111;
		#10;
		whole = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate the fraction
		InputA=reminder; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b0110;
		#10;
		InputA=2; OpCode=4'b0111;
		#10;

		fraction=Result;

		$display("---------------------------\n\nResult: Surface area of a regular pyramid with a base edge %2d and slant height %2d is %3d.%-2d.\n", base1, slant, whole, fraction);

		// EQUATION 9 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		base1 = 39;
		breadth = 22;
		height = 23;

		$display("Calculate: The surface area of a cuboid with lenght %2d, height %2d, and breadth %2d.\n", base1, height, breadth);

		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate lb
		InputA=base1; OpCode=4'b0100;
		#10;
		InputA=breadth; OpCode=4'b0110;
		#10;
		temp=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate bh
		InputA=breadth; OpCode=4'b0100;
		#10;
		InputA=height; OpCode=4'b0110;
		#10;
		temp_2=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate hl
		InputA=height; OpCode=4'b0100;
		#10;
		InputA=base1; OpCode=4'b0110;
		#10;
		temp_3=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate 2 * (lb + bh + hl)  
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=temp_2; OpCode=4'b0100;
		#10;
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=2; OpCode=4'b0110;	
		#10;

		whole=Result;

		$display("---------------------------\n\nResult: Surface area of a cuboid with lenght %2d, height %2d, and breadth %2d is %3d.\n", base1,height,breadth,whole);

		// EQUATION 10 STEPS

		temp = 0;
		temp_2 = 0;
		temp_3 = 0;
		radius = 9;
		height = 13;

		$display("Calculate: The volume of a cone with radius %2d and height %2d.\n", radius, height);

		$display("Since this equation is hard to compute due to presence of multiple fraction values generated during the calculation, the following steps will be executed sequencially:\n  - Compute pi * r\n  - Compute h/3\n  - Multiply whole part of pi * r with the fraction part of h/3\n  - Multiply whole part of h/3 with the fraction of pi * r\n  - Multiply the fraction parts of h/3 and pi * r\n  - Add whole parts and fractions of these computations for the resulting number\n");
		
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate pi * radius^2
		InputA=radius; OpCode=4'b0100;
		#10;
		InputA=radius; OpCode=4'b0110;
		#10;
		InputA=314; OpCode=4'b0110;
		#10;
		temp=Result;
		InputA=100; OpCode=4'b0111;
		#10;
		// holds the intermediate whole
		temp_2=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		// holds the intermidiate fraction
		temp_3=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate h/3
		InputA=height; OpCode=4'b0100;
		#10;
		numerator=Result;
		InputA=3; OpCode=4'b0111;
		#10;
		temp=Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// reminder is one - get the extra fraction and store it in fraction
		InputA=reminder; OpCode=4'b0100;
		#10;
		InputA=99; OpCode=4'b0110;
		#10;
		InputA=3; OpCode=4'b0111;
		#10;
		fraction=Result;
		InputA=reminder; OpCode=4'b0100;
		#10;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate pi * radius^2 * h/3
		InputA=temp_2; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		whole=Result;
		InputA=temp_2; OpCode=4'b0100;
		#10;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate 254 * .33
		InputA=fraction; OpCode=4'b0100;
		#10;
		InputA=temp_2; OpCode=4'b0110;
		#10;
		temp_2 = Result;
		InputA=100; OpCode=4'b0111;
		#10;
		whole = whole + Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp_2; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		temp_2 = fraction;
		fraction = fraction + Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// decompose fraction to whole and fraction
		InputA=fraction; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b0111;
		#10;
		whole = whole + Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=fraction; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		// fraction is now in the range between 0 and 1
		fraction = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate 4 * .34
		InputA=temp_3; OpCode=4'b0100;
		#10;
		InputA=temp; OpCode=4'b0110;
		#10;
		temp = Result;
		InputA=100; OpCode=4'b0111;
		#10;
		whole = whole + Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		// temp_3 now in the range between 0 and 1
		temp = temp_3;
		temp_3 = temp_3 + Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		// calculate .33 x .34 = initial fractions from pi * r^2 & h/3
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=temp_2; OpCode=4'b0110;
		#10;
		temp = Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=10000; OpCode=4'b0111;
		#10;
		whole = whole + Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=temp; OpCode=4'b0100;
		#10;
		InputA=1000; OpCode=4'b1000;
		#10;
		InputA=10; OpCode=4'b0111;
		#10;
		temp_frac = Result;
		fraction = fraction + temp_3 + temp_frac + 17;
		// decompose fraction to whole and fraction
		InputA=fraction; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b0111;
		#10;
		whole = whole + Result;
		InputA=16'd0; OpCode=4'b0001;
		#10;
		InputA=fraction; OpCode=4'b0100;
		#10;
		InputA=100; OpCode=4'b1000;
		#10;
		// fraction is now in the range between 0 and 1
		fraction = Result;

		$display("---------------------------\n\nResult: Volume of a cone of with with radius %1d and height %2d is %3d.%-2d.", radius, height, whole, fraction);
		$display("------------------------------------------------------------------------------------------");
		$display("All equations are calculated successfully...The program has now stopped. Have a good day!!");	
		$finish;

	end
endmodule