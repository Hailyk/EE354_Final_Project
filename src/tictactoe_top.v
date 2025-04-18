`timescale 1ns / 1ps

module tictactoe_top(
	input ClkPort,
	input BtnC,
	input BtnU,
	input BtnR,
	input BtnL,
	input BtnD,
	//VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	
	//SSG signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	
	//output MemOE, MemWR, RamCS,
	output  QuadSpiFlashCS
	);
	wire Reset;
	assign Reset=BtnR && BtnL;
	wire bright;
	wire[9:0] hc, vc;
	wire[15:0] score;
	wire up,down,left,right,select;
	wire [3:0] anode;
	wire [11:0] rgb;
	wire rst;
	
	wire BtnC_pulse, BtnU_pulse, BtnR_pulse, BtnD_pulse, BtnL_pulse;
	
	
	reg [3:0]	SSD;
	wire [3:0]	SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;
	wire [2:0] 	ssdscan_clk;
	
	reg [27:0]	DIV_CLK;
	always @ (posedge ClkPort, posedge Reset)  
	begin : CLOCK_DIVIDER
      if (Reset)
			DIV_CLK <= 0;
	  else
			DIV_CLK <= DIV_CLK + 1'b1;
	end
	
	wire [11:0] background;
	wire [3:0] selector_bit;
	wire [1:0] cursorX;
	wire [1:0] cursorY;
	wire turn;
	wire [8:0] board;
	wire [3:0] PlayerA_Win_Count;
	wire [3:0] PlayerB_Win_Count;
	wire [3:0] Player_Tie_Win_Count;
	
	debouncer #(.N_dc(7)) debouncer_U 
        (.CLK(ClkPort), .RESET(Reset), .PB(BtnU), .DPB(), 
		.SCEN(BtnU_pulse), .MCEN(), .CCEN());
	debouncer #(.N_dc(7)) debouncer_D 
        (.CLK(ClkPort), .RESET(Reset), .PB(BtnD), .DPB(), 
		.SCEN(BtnD_pulse), .MCEN(), .CCEN());
	debouncer #(.N_dc(7)) debouncer_L 
        (.CLK(ClkPort), .RESET(Reset), .PB(BtnL), .DPB(), 
		.SCEN(BtnL_pulse), .MCEN(), .CCEN());
	debouncer #(.N_dc(7)) debouncer_R 
        (.CLK(ClkPort), .RESET(Reset), .PB(BtnR), .DPB(), 
		.SCEN(BtnR_pulse), .MCEN(), .CCEN());
	debouncer #(.N_dc(7)) debouncer_C 
        (.CLK(ClkPort), .RESET(Reset), .PB(BtnC), .DPB(), 
		.SCEN(BtnC_pulse), .MCEN(), .CCEN());
	
	display_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));
	board_controller bc(
		.clk(ClkPort), 
		.bright(bright), 
		.rst(Reset), 
		.up(BtnU_pulse), 
		.down(BtnD_pulse),
		.left(BtnL_pulse),
		.right(BtnR_pulse), 
		.select(BtnC_pulse), 
		.hCount(hc), 
		.vCount(vc), 
		.rgb(rgb), 
		.background(background), 
		.selector_bit(selector_bit), 
		.cursorX(cursorX), 
		.cursorY(cursorY), 
		.turn(turn),
		.board(board),
		.PlayerA_Win_Count(PlayerA_Win_Count),
		.PlayerB_Win_Count(PlayerB_Win_Count),
		.Player_Tie_Win_Count(Player_Tie_Win_Count));

	
	assign vgaR = rgb[11 : 8];
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];
	
	// disable mamory ports
	//assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	assign QuadSpiFlashCS = 1'b1;
	
	//------------
	// SSD (Seven Segment Display)
	// reg [3:0]	SSD;
	// wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	
	//SSDs display 
	assign SSD7 = turn;
	assign SSD6 = 4'b0000;
	assign SSD5 = Player_Tie_Win_Count;
	assign SSD4 = 4'b0000;
	assign SSD3 = Player_Tie_Win_Count;
	assign SSD2 = 4'b0000;
	assign SSD1 = PlayerA_Win_Count;
	assign SSD0 = selector_bit;


	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//

	assign ssdscan_clk = DIV_CLK[19:17];
	assign An0	= !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 000
	assign An1	= !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 001
	assign An2	= !(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 010
	assign An3	= !(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 011
	assign An4	= !( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 100
	assign An5	= !( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 101
	assign An6	= !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 110
	assign An7	= !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 111
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3, SSD4, SSD5, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  3'b000: SSD = SSD0;
				  3'b001: SSD = SSD1;
				  3'b010: SSD = SSD2;
				  3'b011: SSD = SSD3;
				  3'b100: SSD = SSD4;
				  3'b101: SSD = SSD5;
				  3'b110: SSD = SSD6;
				  3'b111: SSD = SSD7;
		endcase 
	end

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9
			4'b1010: SSD_CATHODES = 8'b00010001; // A
			4'b1011: SSD_CATHODES = 8'b11000001; // B
			4'b1100: SSD_CATHODES = 8'b01100011; // C
			4'b1101: SSD_CATHODES = 8'b10000101; // D
			4'b1110: SSD_CATHODES = 8'b01100001; // E
			4'b1111: SSD_CATHODES = 8'b01110001; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	// reg [7:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

endmodule
