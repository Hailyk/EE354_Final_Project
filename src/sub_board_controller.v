`timescale 1ns / 1ps

module sub_board_controller(
	input clk,
	input rst,
	input back,
	input up, down, left, right, select,
	input [9:0] hCount, vCount,
	input [9:0] x_offset, y_offset,
	input [31:0] game_clk,
	input turn,
	input sub_board_selected,
	output reg [11:0] rgb,
	output reg [2:0] win);
	
	reg [8:0] playerA;
	reg [8:0] playerB;
	reg [8:0] board;

	reg [3:0] selector_bit;
	reg [1:0] cursorX;
	reg [1:0] cursorY;
	reg board_flash;
	reg[11:0] end_game_flash;
	
	parameter WHITE   = 12'b1111_1111_1111;
    parameter GRAY    = 12'b1000_1000_1000; // Color for grid lines
	parameter GREEN   = 12'b0000_1111_0000; // selector color
    parameter RED     = 12'b1111_0000_0000; // Player 2 color
    parameter BLUE    = 12'b0000_0000_1111; // Player 1 color
    parameter BLACK   = 12'b0000_0000_0000; // Color outside display area
	
	parameter padding = 2;
	parameter end_game_flash_time = 512;
	
	wire[9:0] x_blank = x_offset + 143;
	wire[9:0] y_blank = y_offset + 34;
	
	assign logic_clk = game_clk[19];
	
	always@ (*) begin
		if (!board_flash) begin
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
			else if(board[0] == 1'b1 && board_cell_background_0_0 && cell_0_0) begin
				if(playerA[0])
					rgb = BLUE;
				else if (playerB[0])
					rgb = RED;
				else 
					rgb = BLACK;
			end
			else if(board[1] == 1'b1 && board_cell_background_1_0 && cell_1_0) begin
				if(playerA[1])
					rgb = BLUE;
				else if (playerB[1])
					rgb = RED;
				else 
					rgb = BLACK;
			end
			else if(board[2] == 1'b1 && board_cell_background_2_0 && cell_2_0) begin
				if(playerA[2])
					rgb = BLUE;
				else if (playerB[2])
					rgb = RED;
				else 
					rgb = BLACK;
			end
			else if(board[3] == 1'b1 && board_cell_background_0_1 && cell_0_1) begin
				if(playerA[3])
					rgb = BLUE;
				else if (playerB[3])
					rgb = RED;
				else 
					rgb = BLACK;
			end
			else if(board[4] == 1'b1 && board_cell_background_1_1 && cell_1_1) begin
				if(playerA[4])
					rgb = BLUE;
				else if (playerB[4])
					rgb = RED;
				else 
					rgb = BLACK;
			end
			else if(board[5] == 1'b1 && board_cell_background_2_1 && cell_2_1) begin
				if(playerA[5])
					rgb = BLUE;
				else if (playerB[5])
					rgb = RED;
				else rgb = BLACK;
			end
			else if(board[6] == 1'b1 && board_cell_background_0_2 && cell_0_2) begin
				if(playerA[6])
					rgb = BLUE;
				else if (playerB[6])
					rgb = RED;
				else rgb = BLACK;
			end
			else if(board[7] == 1'b1 && board_cell_background_1_2 && cell_1_2) begin
				if(playerA[7])
					rgb = BLUE;
				else if (playerB[7])
					rgb = RED;
				else rgb = BLACK;
			end
			else if(board[8] == 1'b1 && board_cell_background_2_2 &&cell_2_2) begin
				if(playerA[8])
					rgb = BLUE;
				else if (playerB[8])
					rgb = RED;
				else
					rgb = BLACK;
			end
			else begin
				rgb = BLACK;
			end
		end
		else begin
			rgb = 11'bxxxxxxxxxxxx;
		end
	end
	
	//board drawing -- SCALE TO BE 1/9 SIZE (decrease each cell side to be 1/3) -> 120 cel width
	assign board_line = (board_v_line_1 || board_v_line_2 || board_h_line_1 || board_h_line_2);
	
	assign board_outline = 	(hCount >= x_blank) && (hCount < x_blank + 120) &&
							(vCount >= y_blank) && (vCount < y_blank + 120);
	
	// Grid Line Definitions
	assign board_v_line_1 = (hCount >= 32 + x_blank) && 	(hCount <= 34 + x_blank) && 
							(vCount >= 0 + y_blank) && 		(vCount <= 100 + y_blank);
	assign board_v_line_2 = (hCount >= 66 + x_blank) && 	(hCount <= 68 + x_blank) && 
							(vCount >= 0 + y_blank) && 		(vCount <= 100 + y_blank);
	assign board_h_line_1 = (hCount >= 0 + x_blank) && 		(hCount <= 100 + x_blank) && 
							(vCount >= 32 + y_blank) && 	(vCount <= 34 + y_blank);
	assign board_h_line_2 = (hCount >= 0 + x_blank) && 		(hCount <= 100 + x_blank) && 
							(vCount >= 66 + y_blank) && 	(vCount <= 68 + y_blank);
	
		// cell background row 0
	assign board_cell_background_0_0 = 	(hCount >= 0 + x_blank) && 	(hCount <= 32 + x_blank) && 
										(vCount >= 0 + y_blank) && 	(vCount <= 32 + y_blank);
	assign board_cell_background_1_0 = 	(hCount >= 34 + x_blank) && 	(hCount <= 66 + x_blank) && 
										(vCount >= 0 + y_blank) && 	(vCount <= 34 + y_blank);
	assign board_cell_background_2_0 = 	(hCount >= 68 + x_blank) && 	(hCount <= 100 + x_blank) && 
										(vCount >= 0 + y_blank) && 	(vCount <= 32 + y_blank);
 
	// cell background row 1
	assign board_cell_background_0_1 = 	(hCount >= 0 + x_blank) && 	(hCount <= 32 + x_blank) && 
										(vCount >= 34 + y_blank) && 	(vCount <= 66 + y_blank);
	assign board_cell_background_1_1 = 	(hCount >= 34 + x_blank) && 	(hCount <= 66 + x_blank) && 
										(vCount >= 34 + y_blank) && 	(vCount <= 66 + y_blank);
	assign board_cell_background_2_1 = 	(hCount >= 68 + x_blank) && 	(hCount <= 100 + x_blank) && 
										(vCount >= 34 + y_blank) && 	(vCount <= 66 + y_blank);
 
	// cell background row 2
	assign board_cell_background_0_2 = 	(hCount >= 0 + x_blank) && 	(hCount <= 32 + x_blank) && 
										(vCount >= 68 + y_blank) && 	(vCount <= 100 + y_blank);
	assign board_cell_background_1_2 = 	(hCount >= 34 + x_blank) && 	(hCount <= 66 + x_blank) && 
										(vCount >= 68 + y_blank) && 	(vCount <= 100 + y_blank);
	assign board_cell_background_2_2 = 	(hCount >= 68 + x_blank) && 	(hCount <= 100 + x_blank) && 
										(vCount >= 68 + y_blank) && 	(vCount <= 100 + y_blank);
 
	// Cell Inner Area Definitions (with padding)
	// cell row 0
	assign cell_0_0 = 	(hCount >= (0   + x_blank + padding)) && 
						(hCount <= (32 + x_blank - padding)) && 
						(vCount >= (0   + y_blank + padding)) && 
						(vCount <= (32 + y_blank - padding));
	assign cell_1_0 = 	(hCount >= (34 + x_blank + padding)) && 
						(hCount <= (66 + x_blank - padding)) && 
						(vCount >= (0   + y_blank + padding)) && 
						(vCount <= (32 + y_blank - padding));
	assign cell_2_0 = 	(hCount >= (68 + x_blank + padding)) && 
						(hCount <= (100 + x_blank - padding)) && 
						(vCount >= (0   + y_blank + padding)) && 
						(vCount <= (32 + y_blank - padding));
 
	// cell row 1
	assign cell_0_1 = 	(hCount >= (0 + x_blank + padding)) && 
						(hCount <= (32 + x_blank - padding)) && 
						(vCount >= (34 + y_blank + padding)) && 
						(vCount <= (66 + y_blank - padding));
	assign cell_1_1 = 	(hCount >= (34 + x_blank + padding)) && 
						(hCount <= (66 + x_blank - padding)) && 
						(vCount >= (34 + y_blank + padding)) && 
						(vCount <= (66 + y_blank - padding));
	assign cell_2_1 = 	(hCount >= (68 + x_blank + padding)) && 
						(hCount <= (100 + x_blank - padding)) && 
						(vCount >= (34 + y_blank + padding)) && 
						(vCount <= (66 + y_blank - padding));
 
	// cell row 2
	assign cell_0_2 = 	(hCount >= (0 + x_blank + padding)) && 
						(hCount <= (32 + x_blank - padding)) && 
						(vCount >= (68 + y_blank + padding)) && 
						(vCount <= (100 + y_blank - padding));
	assign cell_1_2 = 	(hCount >= (34 + x_blank + padding)) && 
						(hCount <= (66 + x_blank - padding)) && 
						(vCount >= (68 + y_blank + padding)) && 
						(vCount <= (100 + y_blank - padding));
	assign cell_2_2 = 	(hCount >= (68 + x_blank + padding)) && 
						(hCount <= (100 + x_blank - padding)) && 
						(vCount >= (68 + y_blank + padding)) && 
						(vCount <= (100 + y_blank - padding));
						
	
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
	
		
	// controller
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			cursorX <= 2'd1;
			cursorY <= 2'd1;
			selector_bit <= 4'd4;
			playerA <= 9'b000000000;
			playerB <= 9'b000000000;
			board <= 9'b000000000;
		end 
		else if (board_full) begin
			playerA <= 9'b000000000;
			playerB <= 9'b000000000;
			board <= 9'b000000000;
		end
		else if (!board_flash && sub_board_selected) begin
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
					board[selector_bit] <= 1'b1;
					if (turn == 1'b0) begin
						playerA[selector_bit] <= 1'b1;
					end 
					else begin
						playerB[selector_bit] <= 1'b1;
					end
				end
			end
		end
	end


	always @(posedge logic_clk, posedge rst) begin
		if (rst) begin
			end_game_flash <= 11'b0000_0000_0000;
			board_flash <= 1'b0;
			win <= 3'b000;
		end 
		else begin
			if ((board_full || playerA_win || playerB_win) && !board_flash) begin
				board_flash <= 1'b1;
				end_game_flash <= 11'b0000_0000_0000;
				if (playerA_win) begin
					win = 3'b001;
				end
				else if (playerB_win) begin
					win = 3'b010;
				end
			end 
			else if (board_flash) begin
				if (end_game_flash == end_game_flash_time) begin
					board_flash <= 1'b0;
					end_game_flash <= 11'b0000_0000_0000;
				end 
				else begin
					end_game_flash <= end_game_flash + 1'b1;
				end
			end 
			else begin
				 end_game_flash <= 11'b0000_0000_0000;
			end
		end
	end
	
	
endmodule
