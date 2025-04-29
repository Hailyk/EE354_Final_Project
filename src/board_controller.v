`timescale 1ns / 1ps

module board_controller(
	input clk,
	input bright,
	input rst,
	input back,
	input up, down, left, right, select,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background,
	output reg [3:0] selector_bit,
	output reg [1:0] cursorX,
	output reg [1:0] cursorY,
	output reg turn,
	output reg [8:0] board,
	output reg [3:0] PlayerA_Win_Count,
	output reg [3:0] PlayerB_Win_Count,
	output reg [3:0] Player_Tie_Win_Count);
	
	reg [8:0] playerA;
	reg [8:0] playerB;
	//reg self_select;
	reg win;
	
	reg win;
	reg[31:0] game_clk;
	reg board_flash;
	reg[11:0] end_game_flash;
	
	wire[11:0] blue_win_img;
	wire[11:0] red_win_img;
	wire[11:0] tie_img;
	wire [19:0] pixel_address;
	reg [11:0]  selected_pixel_data;
	
	wire image_on;
	
	parameter WHITE   = 12'b1111_1111_1111;
    parameter GRAY    = 12'b1000_1000_1000; // Color for grid lines
	parameter GREEN   = 12'b0000_1111_0000; // selector color
    parameter RED     = 12'b1111_0000_0000; // Player 2 color
    parameter BLUE    = 12'b0000_0000_1111; // Player 1 color
    parameter BLACK   = 12'b0000_0000_0000; // Color outside display area
	
	parameter Stored_IMG_width = 190;
	parameter Stored_IMG_height = 190;
	parameter Stored_IMG_pixel = Stored_IMG_width * Stored_IMG_height;
	parameter IMG_width   = Stored_IMG_width * 2;
	parameter IMG_height  = Stored_IMG_height * 2;
	parameter IMG_pixel   = IMG_width * IMG_height;
	
	
	parameter x_offset = 0;
	parameter y_offset = 0;
	parameter padding = 10;
	parameter end_game_flash_time = 512;
	
	parameter x_blank = x_offset + 143;
	parameter y_blank = y_offset + 34;

	wire [$clog2(IMG_width)-1:0] image_hCount = hCount - x_blank;
	wire [$clog2(IMG_height)-1:0] image_vCount = vCount - y_blank;
	
	wire [$clog2(IMG_width)-1:0] image_hCoord;
	wire [$clog2(IMG_height)-1:0] image_vCoord;
	
	wire [$clog2(Stored_IMG_width)-1:0] stored_hCoord;
	wire [$clog2(Stored_IMG_height)-1:0] stored_vCoord;
	
	wire [$clog2(Stored_IMG_pixel)-1:0] bram_address;

	//sub rgb outputs
	wire [11:0] sub_rgb_0;
	wire [11:0] sub_rgb_1;
	wire [11:0] sub_rgb_2;
	wire [11:0] sub_rgb_3;
	wire [11:0] sub_rgb_4;
	wire [11:0] sub_rgb_5;
	wire [11:0] sub_rgb_6;
	wire [11:0] sub_rgb_7;
	wire [11:0] sub_rgb_8;
	
	assign bram_address = stored_vCoord * Stored_IMG_width + stored_hCoord;
	
	assign image_hCoord = (hCount >= x_blank && hCount < x_blank + IMG_width) ? (hCount - x_blank) : 0;
	assign image_vCoord = (vCount >= y_blank && vCount < y_blank + IMG_height) ? (vCount - y_blank) : 0;
	
	assign stored_hCoord = image_hCoord / 2;
	assign stored_vCoord = image_vCoord / 2;

	assign sub_board_rst = rst || (board_flash && end_game_flash == end_game_flash_time);
	
	
	blk_mem_gen_blue blue_bram_inst (
		.clka(clk),
		.ena(board_outline),
		.addra(bram_address),
		.douta(blue_win_img));
	blk_mem_gen_red red_bram_inst (
		.clka(clk),
		.ena(board_outline),
		.addra(bram_address),
		.douta(red_win_img));
	blk_mem_gen_tie tie_bram_inst (
		.clka(clk),
		.ena(board_outline),
		.addra(bram_address),
		.douta(tie_img));


	wire[3:0] sub_selector_bit;
	wire[2:0] sub_cursorX, sub_cursorY;
	reg [8:0] sub_board_selected;
	
	//wire sub board outputs to big board
	wire[2:0] sub_win_0;
	wire[2:0] sub_win_1;
	wire[2:0] sub_win_2;
	wire[2:0] sub_win_3;
	wire[2:0] sub_win_4;
	wire[2:0] sub_win_5;
	wire[2:0] sub_win_6;
	wire[2:0] sub_win_7;
	wire[2:0] sub_win_8;

	//wire sub board outputs to big board
	// wire[3:0] sub_selector_0;
	// wire[3:0] sub_selector_1;
	// wire[3:0] sub_selector_2;
	// wire[3:0] sub_selector_3;
	// wire[3:0] sub_selector_4;
	// wire[3:0] sub_selector_5;
	// wire[3:0] sub_selector_6;
	// wire[3:0] sub_selector_7;
	// wire[3:0] sub_selector_8;

	
	// latch any new sub-board results forever
	//	once a result goes high it will stay high
	always @ (posedge clk, posedge rst) begin
		if (rst) begin
			playerA <= 9'b0;
			playerB <= 9'b0;
			board   <= 9'b0;
		end 
		else begin
		playerA[0] <= playerA[0] | sub_win_0[0];
			playerA[1] <= playerA[1] | sub_win_1[0];
			playerA[2] <= playerA[2] | sub_win_2[0];
			playerA[3] <= playerA[3] | sub_win_3[0];
			playerA[4] <= playerA[4] | sub_win_4[0];
			playerA[5] <= playerA[5] | sub_win_5[0];
			playerA[6] <= playerA[6] | sub_win_6[0];
			playerA[7] <= playerA[7] | sub_win_7[0];
			playerA[8] <= playerA[8] | sub_win_8[0];

			playerB[0] <= playerB[0] | sub_win_0[1];
			playerB[1] <= playerB[1] | sub_win_1[1];
			playerB[2] <= playerB[2] | sub_win_2[1];
			playerB[3] <= playerB[3] | sub_win_3[1];
			playerB[4] <= playerB[4] | sub_win_4[1];
			playerB[5] <= playerB[5] | sub_win_5[1];
			playerB[6] <= playerB[6] | sub_win_6[1];
			playerB[7] <= playerB[7] | sub_win_7[1];
			playerB[8] <= playerB[8] | sub_win_8[1];

			board[0]   <= board[0]   | sub_win_0[2];
			board[1]   <= board[1]   | sub_win_1[2];
			board[2]   <= board[2]   | sub_win_2[2];
			board[3]   <= board[3]   | sub_win_3[2];
			board[4]   <= board[4]   | sub_win_4[2];
			board[5]   <= board[5]   | sub_win_5[2];
			board[6]   <= board[6]   | sub_win_6[2];
			board[7]   <= board[7]   | sub_win_7[2];
			board[8]   <= board[8]   | sub_win_8[2];
		end
	end
	//row 0
	sub_board_controller sub_board_0_0 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(10),
	.y_offset(10),
	.game_clk(game_clk),
	.rgb(sub_rgb_0),
	.turn(turn),
	.sub_board_selected(sub_board_selected[0]),
	.win(sub_win_0));

	sub_board_controller sub_board_1_0 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(140),
	.y_offset(10),
	.game_clk(game_clk),
	.rgb(sub_rgb_1),
	.turn(turn),
	.sub_board_selected(sub_board_selected[1]),
	.win(sub_win_1));

	sub_board_controller sub_board_2_0 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(270),
	.y_offset(10),
	.game_clk(game_clk),
	.rgb(sub_rgb_2),
	.turn(turn),
	.sub_board_selected(sub_board_selected[2]),
	.win(sub_win_2));
	
	//row 2
	sub_board_controller sub_board_0_1 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(10),
	.y_offset(140),
	.game_clk(game_clk),
	.rgb(sub_rgb_3),
	.turn(turn),
	.sub_board_selected(sub_board_selected[3]),
	.win(sub_win_3));

	sub_board_controller sub_board_1_1 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(140),
	.y_offset(140),
	.game_clk(game_clk),
	.rgb(sub_rgb_4),
	.turn(turn),
	.sub_board_selected(sub_board_selected[4]),
	.win(sub_win_4));

	sub_board_controller sub_board_2_1 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(270),
	.y_offset(140),
	.game_clk(game_clk),
	.rgb(sub_rgb_5),
	.turn(turn),
	.sub_board_selected(sub_board_selected[5]),
	.win(sub_win_5));

	//row 3
	sub_board_controller sub_board_0_2 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(10),
	.y_offset(270),
	.game_clk(game_clk),
	.rgb(sub_rgb_6),
	.turn(turn),
	.sub_board_selected(sub_board_selected[6]),
	.win(sub_win_6));

	sub_board_controller sub_board_1_2 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(140),
	.y_offset(270),
	.game_clk(game_clk),
	.rgb(sub_rgb_7),
	.turn(turn),
	.sub_board_selected(sub_board_selected[7]),
	.win(sub_win_7));

	sub_board_controller sub_board_2_2 (
	.clk(clk),
	.rst(sub_board_rst),
	.back(back),
	.up(up),
	.down(down), 
	.left(left), 
	.right(right),
	.select(select),
	.hCount(hCount),
	.vCount(vCount),
	.x_offset(270),
	.y_offset(270),
	.game_clk(game_clk),
	.rgb(sub_rgb_8),
	.turn(turn),
	.sub_board_selected(sub_board_selected[8]),
	.win(sub_win_8));
	
	always@ (posedge clk, posedge rst) begin
		if(rst)
			game_clk <= 23'b0000_0000_0000_0000_0000_0000_0000_0000;
		else
			game_clk <= game_clk + 1'b1;
	end
	
	assign logic_clk = game_clk[19];
	
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = BLACK;
		else if (win && board_outline) begin
			if (board_full) begin
				rgb = tie_img;
			end
			else if (playerA_win) begin
				rgb = blue_win_img;
			end
			else if (playerB_win) begin
				rgb = red_win_img;
			end
			else begin
				rgb = BLACK;
			end
		end
		else if (board_flash && !board_outline) begin
			rgb = BLACK;
		end
		else if (!board_flash) begin
			if(board_line) begin
				rgb = GRAY;
			end
			else if(selector_bit == 0 && board_cell_background_0_0 && !cell_0_0 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 1 && board_cell_background_1_0 && !cell_1_0 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 2 && board_cell_background_2_0 && !cell_2_0 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 3 && board_cell_background_0_1 && !cell_0_1 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 4 && board_cell_background_1_1 && !cell_1_1 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 5 && board_cell_background_2_1 && !cell_2_1 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 6 && board_cell_background_0_2 && !cell_0_2 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 7 && board_cell_background_1_2 && !cell_1_2 && game_clk[26]) begin
				rgb = WHITE;
			end
			else if(selector_bit == 8 && board_cell_background_2_2 && !cell_2_2 && game_clk[26]) begin
				rgb = WHITE;
			end
			//row 1
			else if (board_cell_background_0_0 && cell_0_0) begin 
				if(sub_win_0 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_0 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_0 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_0;
				end
			end
			else if (board_cell_background_1_0 && cell_1_0) begin 
				if(sub_win_1 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_1 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_1 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_1;
				end
			end
			else if (board_cell_background_2_0 && cell_2_0) begin 
				if(sub_win_2 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_2 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_2 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_2;
				end
			end
			//row 2
			else if (board_cell_background_0_1 && cell_0_1) begin 
				if(sub_win_3 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_3 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_3 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_3;
				end
			end
			else if (board_cell_background_1_1 && cell_1_1) begin 
				if(sub_win_4 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_4 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_4 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_4;
				end
			end
			else if (board_cell_background_2_1 && cell_2_1) begin 
				if(sub_win_5 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_5 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_5 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_5;
				end
			end
			//row3
			else if (board_cell_background_0_2 && cell_0_2) begin 
				if(sub_win_6 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_6 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_6 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_6;
				end
			end
			else if (board_cell_background_1_2 && cell_1_2) begin 
				if(sub_win_7 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_7 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_7 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_7;
				end
			end
			else if (board_cell_background_2_2 && cell_2_2) begin 
				if(sub_win_8 == 3'b101)begin
					rgb = BLUE;
				end
				else if(sub_win_8 == 3'b110)begin
					rgb = RED;
				end
				else if(sub_win_8 == 3'b100)begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_8;
				end
			end
			else begin
				rgb = BLACK;
			end
		end
		else begin
			rgb = 11'bxxxxxxxxxxxx;
		end
	end
	
	assign board_line = (board_v_line_1 || board_v_line_2 || board_h_line_1 || board_h_line_2);
	
	assign board_outline = 	(hCount >= x_blank) && (hCount < x_blank + IMG_width) &&
							(vCount >= y_blank) && (vCount < y_blank + IMG_height);
	
	// Grid Line Definitions
	assign board_v_line_1 = (hCount >= 120 + x_blank) && 	(hCount <= 130 + x_blank) && 
							(vCount >= 0 + y_blank) && 	(vCount <= 380 + y_blank);
	assign board_v_line_2 = (hCount >= 250 + x_blank) && 	(hCount <= 260 + x_blank) && 
							(vCount >= 0 + y_blank) && 	(vCount <= 380 + y_blank);
	assign board_h_line_1 = (hCount >= 0 + x_blank) && 	(hCount <= 380 + x_blank) && 
							(vCount >= 120 + y_blank) && 	(vCount <= 130 + y_blank);
	assign board_h_line_2 = (hCount >= 0 + x_blank) && 	(hCount <= 380 + x_blank) && 
							(vCount >= 250 + y_blank) && 	(vCount <= 260 + y_blank);
	
	// cell background row 0
	assign board_cell_background_0_0 = 	(hCount >= 0 + x_blank) && 	(hCount <= 120 + x_blank) && 
										(vCount >= 0 + y_blank) && 	(vCount <= 120 + y_blank);
	assign board_cell_background_1_0 = 	(hCount >= 130 + x_blank) && 	(hCount <= 250 + x_blank) && 
										(vCount >= 0 + y_blank) && 	(vCount <= 120 + y_blank);
	assign board_cell_background_2_0 = 	(hCount >= 260 + x_blank) && 	(hCount <= 380 + x_blank) && 
										(vCount >= 0 + y_blank) && 	(vCount <= 120 + y_blank);
	
	// cell background row 1
	assign board_cell_background_0_1 = 	(hCount >= 0 + x_blank) && 	(hCount <= 120 + x_blank) && 
										(vCount >= 130 + y_blank) && 	(vCount <= 250 + y_blank);
	assign board_cell_background_1_1 = 	(hCount >= 130 + x_blank) && 	(hCount <= 250 + x_blank) && 
										(vCount >= 130 + y_blank) && 	(vCount <= 250 + y_blank);
	assign board_cell_background_2_1 = 	(hCount >= 260 + x_blank) && 	(hCount <= 380 + x_blank) && 
										(vCount >= 130 + y_blank) && 	(vCount <= 250 + y_blank);
	
	// cell background row 2
	assign board_cell_background_0_2 = 	(hCount >= 0 + x_blank) && 	(hCount <= 120 + x_blank) && 
										(vCount >= 260 + y_blank) && 	(vCount <= 380 + y_blank);
	assign board_cell_background_1_2 = 	(hCount >= 130 + x_blank) && 	(hCount <= 250 + x_blank) && 
										(vCount >= 260 + y_blank) && 	(vCount <= 380 + y_blank);
	assign board_cell_background_2_2 = 	(hCount >= 260 + x_blank) && 	(hCount <= 380 + x_blank) && 
										(vCount >= 260 + y_blank) && 	(vCount <= 380 + y_blank);
	
	// Cell Inner Area Definitions (with padding)
	// cell row 0
	assign cell_0_0 = 	(hCount >= (0   + x_blank + padding)) && 
						(hCount <= (120 + x_blank - padding)) && 
						(vCount >= (0   + y_blank + padding)) && 
						(vCount <= (120 + y_blank - padding));
	assign cell_1_0 = 	(hCount >= (130 + x_blank + padding)) && 
						(hCount <= (250 + x_blank - padding)) && 
						(vCount >= (0   + y_blank + padding)) && 
						(vCount <= (120 + y_blank - padding));
	assign cell_2_0 = 	(hCount >= (260 + x_blank + padding)) && 
						(hCount <= (380 + x_blank - padding)) && 
						(vCount >= (0   + y_blank + padding)) && 
						(vCount <= (120 + y_blank - padding));

	// cell row 1
	assign cell_0_1 = 	(hCount >= (0 + x_blank + padding)) && 
						(hCount <= (120 + x_blank - padding)) && 
						(vCount >= (130 + y_blank + padding)) && 
						(vCount <= (250 + y_blank - padding));
	assign cell_1_1 = 	(hCount >= (130 + x_blank + padding)) && 
						(hCount <= (250 + x_blank - padding)) && 
						(vCount >= (130 + y_blank + padding)) && 
						(vCount <= (250 + y_blank - padding));
	assign cell_2_1 = 	(hCount >= (260 + x_blank + padding)) && 
						(hCount <= (380 + x_blank - padding)) && 
						(vCount >= (130 + y_blank + padding)) && 
						(vCount <= (250 + y_blank - padding));

	// cell row 2
	assign cell_0_2 = 	(hCount >= (0 + x_blank + padding)) && 
						(hCount <= (120 + x_blank - padding)) && 
						(vCount >= (260 + y_blank + padding)) && 
						(vCount <= (380 + y_blank - padding));
	assign cell_1_2 = 	(hCount >= (130 + x_blank + padding)) && 
						(hCount <= (250 + x_blank - padding)) && 
						(vCount >= (260 + y_blank + padding)) && 
						(vCount <= (380 + y_blank - padding));
	assign cell_2_2 = 	(hCount >= (260 + x_blank + padding)) && 
						(hCount <= (380 + x_blank - padding)) && 
						(vCount >= (260 + y_blank + padding)) && 
						(vCount <= (380 + y_blank - padding));

	
	function reg checkboard (input reg [8:0] board);
    reg playerWin;
    reg row0, row1, row2;
    reg col0, col1, col2;
    reg diag0, diag1;

        begin
            row0 = board[0] & board[1] & board[2];
            row1 = board[3] & board[4] & board[5];
            row2 = board[6] & board[7] & board[8];
    
            col0 = board[0] & board[3] & board[6];
            col1 = board[1] & board[4] & board[7];
            col2 = board[2] & board[5] & board[8];
    
            diag0 = board[0] & board[4] & board[8];
            diag1 = board[2] & board[4] & board[6];
    
            playerWin = row0 | row1 | row2 | col0 | col1 | col2 | diag0 | diag1;
    
            checkboard = playerWin;
        end
    endfunction
	
	
	assign playerA_win = checkboard(playerA);
	assign playerB_win = checkboard(playerB);
	assign board_full = board == 9'b1_1111_1111;
	
	always @(posedge clk or posedge rst) begin
  		if (rst) 
    		win <= 1'b0;
  		else 
    		win <= win | playerA_win | playerB_win | board_full;
	end
	
		
	// controller
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			cursorX <= 2'd1;
			cursorY <= 2	'd1;
			selector_bit <= 4'd4;
			playerA <= 9'b000000000;
			playerB <= 9'b000000000;
			board <= 9'b000000000;
			turn <= 1'b0;
			sub_board_selected = 9'b000000000;
			//self_select = 1'b1;
		end 
		else if (board_flash && end_game_flash == end_game_flash_time) begin
			playerA <= 9'b000000000;
			playerB <= 9'b000000000;
			board <= 9'b000000000;
			turn <= 1'b0;
		end 
		else if (!board_flash) begin
			if(sub_board_selected == 9'b000000000)begin
				if (left) begin
					if (cursorX > 0) begin
						cursorX <= cursorX - 1;
						selector_bit <= selector_bit - 1;
					end
				end else if (right) begin
					if (cursorX < 2) begin
						cursorX <= cursorX + 1;
						selector_bit <= selector_bit + 1;
					end
				end 
				else if (up) begin
					if (cursorY > 0) begin
						cursorY <= cursorY - 1;
						selector_bit <= selector_bit - 3;
					end
				end 
				else if (down) begin
					if (cursorY < 2) begin
						cursorY <= cursorY + 1;
						selector_bit <= selector_bit + 3;
					end
				end 
				else if (select) begin
					if (board[selector_bit] == 1'b0) begin
						sub_board_selected[selector_bit] <= 1'b1;
						//self_select <= 1'b0;
 					end
				end
			end
			else begin
				if(select)begin
					if (turn == 1'b0) begin
							turn <= 1'b1;
						end 
					else begin
							turn <= 1'b0;
					end
					// case(sub_board_selected)
					// 	9'b000000001: selector_bit <= sub_selector_0;
					// 	9'b000000010: selector_bit <= sub_selector_1;
					// 	9'b000000100: selector_bit <= sub_selector_2;
					// 	9'b000001000: selector_bit <= sub_selector_3;
					// 	9'b000010000: selector_bit <= sub_selector_4;
					// 	9'b000100000: selector_bit <= sub_selector_5;
					// 	9'b001000000: selector_bit <= sub_selector_6;
					// 	9'b010000000: selector_bit <= sub_selector_7;
					// 	9'b100000000: selector_bit <= sub_selector_8;
					// 	default 
					// endcase
					sub_board_selected <=  9'b000000000;				
				end
				else if(back)begin
					sub_board_selected <=  9'b000000000;
				end
			end
		end
	end


	always @(posedge logic_clk, posedge rst) begin
		if (rst) begin
			end_game_flash <= 12'b0000_0000_0000;
			board_flash <= 1'b0;
		end 
		else begin
			if (win && !board_flash) begin
				board_flash <= 1'b1;
				end_game_flash <= 12'b0000_0000_0000;
				if (board_full) begin
					Player_Tie_Win_Count = Player_Tie_Win_Count + 1'b1;
				end
				else if (playerA_win) begin
					PlayerA_Win_Count = PlayerA_Win_Count + 1'b1;
				end
				else if (playerB_win) begin
					PlayerB_Win_Count = PlayerB_Win_Count + 1'b1;
				end
			end 
			else if (board_flash) begin
				if (end_game_flash < end_game_flash_time) begin
					end_game_flash <= end_game_flash + 1;
				end else begin
					board_flash <= 1'b0;
					win <= 1'b0;
					end_game_flash <= 12'b0000_0000_0000;
				end
			end
		end
	end
endmodule