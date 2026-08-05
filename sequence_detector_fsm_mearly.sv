module sequence_detector_fsm_moore (
    input  logic clk,
    input  logic rst,
    input  logic data_in,
    output logic is_valid
);
  typedef enum logic [1:0] {
    IDLE = 2'b00,
    D1   = 2'b01,
    D11  = 2'b10,
    D110 = 2'b11
  } state_t;

  state_t current_state, next_state;

  always_ff @(posedge clk)
    if (rst) current_state <= IDLE;
    else current_state <= next_state;

  always_comb begin
    next_state = current_state;
    is_valid   = 0;
    case (current_state)
      IDLE: begin
        if (data_in) next_state = D1;
        else next_state = IDLE;
      end
      D1: begin
        if (data_in) next_state = D11;
        else next_state = IDLE;
      end
      D11: begin
        if (data_in) next_state = D11;
        else next_state = D110;

      end

      D110: begin
        if (data_in) begin
          is_valid   = 1;
          next_state = D1;
        end else next_state = IDLE;
      end
      default: next_state = IDLE;
    endcase
  end

endmodule
