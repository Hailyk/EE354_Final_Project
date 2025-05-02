`timescale 1ns / 1ps

module board_controller(
	input clk,
	input bright,
	input rst,
	input back,
	input up, down, left, right, select,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [3:0] selector_bit,
	output reg [1:0] cursorX,
	output reg [1:0] cursorY,
	output reg turn,
	output reg [3:0] PlayerA_Win_Count,
	output reg [3:0] PlayerB_Win_Count,
	output reg [3:0] Player_Tie_Win_Count,
	output reg [8:0] debug);
	
	wire [8:0] playerA;
	wire [8:0] playerB;
	wire [8:0] board;
	//reg self_select;
	
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
    parameter RED     = 12'b1111_0000_0000; // Player 2 color
    parameter BLUE    = 12'b0000_0000_1111; // Player 1 color
    parameter BLACK   = 12'b0000_0000_0000; // Color outside display area
	
	parameter Stored_IMG_width = 190;
	parameter Stored_IMG_height = 190;
	parameter Stored_IMG_pixel = Stored_IMG_width * Stored_IMG_height;
	parameter IMG_width   = Stored_IMG_width * 2;
	parameter IMG_height  = Stored_IMG_height * 2;
	parameter IMG_pixel   = IMG_width * IMG_height;
	
	parameter x_blank = 143;
	parameter y_blank = 34;
	
	parameter x_offset = 130 + x_blank;
	parameter y_offset = 50 + y_blank;
	parameter padding = 10;
	parameter end_game_flash_time = 512;

	wire [$clog2(IMG_width)-1:0] image_hCount = hCount - x_offset;
	wire [$clog2(IMG_height)-1:0] image_vCount = vCount - y_offset;
	
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
	
	assign image_hCoord = (hCount >= x_offset && hCount < x_offset + IMG_width) ? (hCount - x_offset) : 0;
	assign image_vCoord = (vCount >= y_offset && vCount < y_offset + IMG_height) ? (vCount - y_offset) : 0;
	
	assign stored_hCoord = image_hCoord / 2;
	assign stored_vCoord = image_vCoord / 2;

	assign sub_board_rst = rst || (board_flash && end_game_flash == end_game_flash_time);
	
	wire placed_0_0;
	wire placed_1_0;
	wire placed_2_0;
	wire placed_0_1;
	wire placed_1_1;
	wire placed_2_1;
	wire placed_0_2;
	wire placed_1_2;
	wire placed_2_2;
	
	assign placed = placed_0_0 || placed_1_0 || placed_2_0 ||
					placed_0_1 || placed_1_1 || placed_2_1 ||
					placed_0_2 || placed_1_2 || placed_2_2;
	
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
	
	// Wires to capture outputs from sub-board instances
	
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
	.x_offset(10+x_offset),
	.y_offset(10+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_0),
	.turn(turn),
	.placed(placed_0_0),
	.sub_board_selected(sub_board_selected[0]),
	.win_blue(playerA[0]),
	.win_red(playerB[0]),
	.big_board(board[0]));

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
	.x_offset(140+x_offset),
	.y_offset(10+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_1),
	.turn(turn),
	.placed(placed_1_0),
	.sub_board_selected(sub_board_selected[1]),
	.win_blue(playerA[1]),
	.win_red(playerB[1]),
	.big_board(board[1]));

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
	.x_offset(270+x_offset),
	.y_offset(10+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_2),
	.turn(turn),
	.placed(placed_2_0),
	.sub_board_selected(sub_board_selected[2]),
	.win_blue(playerA[2]),
	.win_red(playerB[2]),
	.big_board(board[2]));
	
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
	.x_offset(10+x_offset),
	.y_offset(140+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_3),
	.turn(turn),
	.placed(placed_0_1),
	.sub_board_selected(sub_board_selected[3]),
	.win_blue(playerA[3]),
	.win_red(playerB[3]),
	.big_board(board[3]));

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
	.x_offset(140+x_offset),
	.y_offset(140+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_4),
	.turn(turn),
	.placed(placed_1_1),
	.sub_board_selected(sub_board_selected[4]),
	.win_blue(playerA[4]),
	.win_red(playerB[4]),
	.big_board(board[4]));

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
	.x_offset(270+x_offset),
	.y_offset(140+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_5),
	.turn(turn),
	.placed(placed_2_1),
	.sub_board_selected(sub_board_selected[5]),
	.win_blue(playerA[5]),
	.win_red(playerB[5]),
	.big_board(board[5]));

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
	.x_offset(10+x_offset),
	.y_offset(270+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_6),
	.turn(turn),
	.placed(placed_0_2),
	.sub_board_selected(sub_board_selected[6]),
	.win_blue(playerA[6]),
	.win_red(playerB[6]),
	.big_board(board[6]));

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
	.x_offset(140+x_offset),
	.y_offset(270+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_7),
	.turn(turn),
	.placed(placed_1_2),
	.sub_board_selected(sub_board_selected[7]),
	.win_blue(playerA[7]),
	.win_red(playerB[7]),
	.big_board(board[7]));

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
	.x_offset(270+x_offset),
	.y_offset(270+y_offset),
	.game_clk(game_clk),
	.rgb(sub_rgb_8),
	.turn(turn),
	.placed(placed_2_2),
	.sub_board_selected(sub_board_selected[8]),
	.win_blue(playerA[8]),
	.win_red(playerB[8]),
	.big_board(board[8]));
	
	
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
				if(playerA[0] && board[0])begin
					rgb = BLUE;
				end
				else if(playerB[0] && board[0])begin
					rgb = RED;
				end
				else if(!playerA[0] && !playerB[0] && board[0]) begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_0;
				end
			end
			else if (board_cell_background_1_0 && cell_1_0) begin 
				if(playerA[1] && board[1])begin
					rgb = BLUE;
				end
				else if(playerB[1] && board[1])begin
					rgb = RED;
				end
				else if(!playerA[1] && !playerB[1] && board[1]) begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_1;
				end
			end
			else if (board_cell_background_2_0 && cell_2_0) begin 
				if(playerA[2] && board[2])begin
					rgb = BLUE;
				end
				else if(playerB[2] && board[2])begin
					rgb = RED;
				end
				else if(!playerA[2] && !playerB[2] && board[2]) begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_2;
				end
			end
			//row 2
			else if (board_cell_background_0_1 && cell_0_1) begin 
				if(playerA[3] && board[3])begin
					rgb = BLUE;
				end
				else if(playerB[3] && board[3])begin
					rgb = RED;
				end
				else if(!playerA[3] && !playerB[3] && board[3]) begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_3;
				end
			end
			else if (board_cell_background_1_1 && cell_1_1) begin 
				if(playerA[4] && board[4])begin
					rgb = BLUE;
				end
				else if(playerB[4] && board[4])begin
					rgb = RED;
				end
				else if(!playerA[4] && !playerB[4] && board[4]) begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_4;
				end
			end
			else if (board_cell_background_2_1 && cell_2_1) begin 
				if(playerA[5] && board[5])begin
					rgb = BLUE;
				end
				else if(playerB[5] && board[5])begin
					rgb = RED;
				end
				else if(!playerA[5] && !playerB[5] && board[5])begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_5;
				end
			end
			//row3
			else if (board_cell_background_0_2 && cell_0_2) begin 
				if(playerA[6] && board[6])begin
					rgb = BLUE;
				end
				else if(playerB[6] && board[6])begin
					rgb = RED;
				end
				else if(!playerA[6] && !playerB[6] && board[6]) begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_6;
				end
			end
			else if (board_cell_background_1_2 && cell_1_2) begin 
				if(playerA[7] && board[7])begin
					rgb = BLUE;
				end
				else if(playerB[7] && board[7])begin
					rgb = RED;
				end
				else if(!playerA[7] && !playerB[7] && board[7]) begin
					rgb = GRAY;
				end
				else begin
					rgb = sub_rgb_7;
				end
			end
			else if (board_cell_background_2_2 && cell_2_2) begin 
				if(playerA[8] && board[8])begin
					rgb = BLUE;
				end
				else if(playerB[8] && board[8])begin
					rgb = RED;
				end
				else if(!playerA[8] && !playerB[8] && board[8]) begin
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
			rgb = 11'bxxxxxxxxxxx;
		end
	end
	
	assign board_line = (board_v_line_1 || board_v_line_2 || board_h_line_1 || board_h_line_2);
	
	assign board_outline = 	(hCount >= x_offset) && (hCount < x_offset + IMG_width) &&
							(vCount >= y_offset) && (vCount < y_offset + IMG_height);
	
	// Grid Line Definitions
	assign board_v_line_1 = (hCount >= 120 + x_offset) && 	(hCount <= 130 + x_offset) && 
							(vCount >= 0 + y_offset) && 	(vCount <= 380 + y_offset);
	assign board_v_line_2 = (hCount >= 250 + x_offset) && 	(hCount <= 260 + x_offset) && 
							(vCount >= 0 + y_offset) && 	(vCount <= 380 + y_offset);
	assign board_h_line_1 = (hCount >= 0 + x_offset) && 	(hCount <= 380 + x_offset) && 
							(vCount >= 120 + y_offset) && 	(vCount <= 130 + y_offset);
	assign board_h_line_2 = (hCount >= 0 + x_offset) && 	(hCount <= 380 + x_offset) && 
							(vCount >= 250 + y_offset) && 	(vCount <= 260 + y_offset);
	
	// cell background row 0
	assign board_cell_background_0_0 = 	(hCount >= 0 + x_offset) && 	(hCount <= 120 + x_offset) && 
										(vCount >= 0 + y_offset) && 	(vCount <= 120 + y_offset);
	assign board_cell_background_1_0 = 	(hCount >= 130 + x_offset) && 	(hCount <= 250 + x_offset) && 
										(vCount >= 0 + y_offset) && 	(vCount <= 120 + y_offset);
	assign board_cell_background_2_0 = 	(hCount >= 260 + x_offset) && 	(hCount <= 380 + x_offset) && 
										(vCount >= 0 + y_offset) && 	(vCount <= 120 + y_offset);
	
	// cell background row 1
	assign board_cell_background_0_1 = 	(hCount >= 0 + x_offset) && 	(hCount <= 120 + x_offset) && 
										(vCount >= 130 + y_offset) && 	(vCount <= 250 + y_offset);
	assign board_cell_background_1_1 = 	(hCount >= 130 + x_offset) && 	(hCount <= 250 + x_offset) && 
										(vCount >= 130 + y_offset) && 	(vCount <= 250 + y_offset);
	assign board_cell_background_2_1 = 	(hCount >= 260 + x_offset) && 	(hCount <= 380 + x_offset) && 
										(vCount >= 130 + y_offset) && 	(vCount <= 250 + y_offset);
	
	// cell background row 2
	assign board_cell_background_0_2 = 	(hCount >= 0 + x_offset) && 	(hCount <= 120 + x_offset) && 
										(vCount >= 260 + y_offset) && 	(vCount <= 380 + y_offset);
	assign board_cell_background_1_2 = 	(hCount >= 130 + x_offset) && 	(hCount <= 250 + x_offset) && 
										(vCount >= 260 + y_offset) && 	(vCount <= 380 + y_offset);
	assign board_cell_background_2_2 = 	(hCount >= 260 + x_offset) && 	(hCount <= 380 + x_offset) && 
										(vCount >= 260 + y_offset) && 	(vCount <= 380 + y_offset);
	
	// Cell Inner Area Definitions (with padding)
	// cell row 0
	assign cell_0_0 = 	(hCount >= (0   + x_offset + padding)) && 
						(hCount <= (120 + x_offset - padding)) && 
						(vCount >= (0   + y_offset + padding)) && 
						(vCount <= (120 + y_offset - padding));
	assign cell_1_0 = 	(hCount >= (130 + x_offset + padding)) && 
						(hCount <= (250 + x_offset - padding)) && 
						(vCount >= (0   + y_offset + padding)) && 
						(vCount <= (120 + y_offset - padding));
	assign cell_2_0 = 	(hCount >= (260 + x_offset + padding)) && 
						(hCount <= (380 + x_offset - padding)) && 
						(vCount >= (0   + y_offset + padding)) && 
						(vCount <= (120 + y_offset - padding));

	// cell row 1
	assign cell_0_1 = 	(hCount >= (0 + x_offset + padding)) && 
						(hCount <= (120 + x_offset - padding)) && 
						(vCount >= (130 + y_offset + padding)) && 
						(vCount <= (250 + y_offset - padding));
	assign cell_1_1 = 	(hCount >= (130 + x_offset + padding)) && 
						(hCount <= (250 + x_offset - padding)) && 
						(vCount >= (130 + y_offset + padding)) && 
						(vCount <= (250 + y_offset - padding));
	assign cell_2_1 = 	(hCount >= (260 + x_offset + padding)) && 
						(hCount <= (380 + x_offset - padding)) && 
						(vCount >= (130 + y_offset + padding)) && 
						(vCount <= (250 + y_offset - padding));

	// cell row 2
	assign cell_0_2 = 	(hCount >= (0 + x_offset + padding)) && 
						(hCount <= (120 + x_offset - padding)) && 
						(vCount >= (260 + y_offset + padding)) && 
						(vCount <= (380 + y_offset - padding));
	assign cell_1_2 = 	(hCount >= (130 + x_offset + padding)) && 
						(hCount <= (250 + x_offset - padding)) && 
						(vCount >= (260 + y_offset + padding)) && 
						(vCount <= (380 + y_offset - padding));
	assign cell_2_2 = 	(hCount >= (260 + x_offset + padding)) && 
						(hCount <= (380 + x_offset - padding)) && 
						(vCount >= (260 + y_offset + padding)) && 
						(vCount <= (380 + y_offset - padding));

	
	function reg checkboard (input [8:0] board);
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
	
		
	// controller
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			cursorX <= 2'd1;
			cursorY <= 2	'd1;
			selector_bit <= 4'd4;
			turn <= 1'b0;
			sub_board_selected = 9'b000000000;
			//self_select = 1'b1;
		end 
		else if (board_flash && end_game_flash == end_game_flash_time) begin
			turn <= 1'b0;
		end 
		else if (!board_flash) begin
			if(sub_board_selected == 9'b000000000) begin
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
 					end
				end
			end
			else begin
				if(placed) begin
					if (turn == 1'b0) begin
							turn <= 1'b1;
						end 
					else begin
							turn <= 1'b0;
					end
					sub_board_selected <=  9'b0;
				end
				else if(back) begin
					sub_board_selected <=  9'b0;
				end
			end
		end
	end
	
	always @(posedge logic_clk, posedge rst) begin
		if (rst) begin
			win <= 1'b0;
			end_game_flash <= 12'b0;
			board_flash <= 1'b0;
			
			PlayerA_Win_Count <= 4'b0;
			PlayerB_Win_Count <= 4'b0;
			Player_Tie_Win_Count <= 4'b0;
		end 
		else if (board_flash && end_game_flash == end_game_flash_time) begin
			 win <= 1'b0;
			 board_flash <= 1'b0;
			 end_game_flash <= 12'b0;
		end 
		else if (!board_flash) begin
			if (!win) begin
				if (checkboard(playerA) || checkboard(playerB) || (board == 9'b111111111)) begin
					win <= 1'b1;
					board_flash <= 1'b1;
					end_game_flash <= 12'b0;

					if (checkboard(playerA)) begin
						PlayerA_Win_Count <= PlayerA_Win_Count + 1'b1;
					end
					else if (checkboard(playerB)) begin
						PlayerB_Win_Count <= PlayerB_Win_Count + 1'b1;
					end
					else if (board == 9'b111111111) begin
						Player_Tie_Win_Count <= Player_Tie_Win_Count + 1'b1;
					end
				end
			end
        end 
        else if (board_flash) begin
            if (end_game_flash < end_game_flash_time) begin
                end_game_flash <= end_game_flash + 1;
            end
        end
    end
	
endmodule