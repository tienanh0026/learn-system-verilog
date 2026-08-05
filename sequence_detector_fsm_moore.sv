module sequence_detector_fsm_moore (
    input  logic clk,
    input  logic rst,
    input  logic data_in,
    output logic is_valid
);
  typedef enum logic [2:0] {
    IDLE = 3'b000,
    D1 = 3'b001,
    D11 = 3'b010,
    D110 = 3'b011,
    D1101 = 3'b100
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
        if (data_in) next_state = next_state;
        else next_state = D110;
      end
      D110: begin
        if (data_in) next_state = D1101;
        else next_state = IDLE;
      end
      D1101: begin
        is_valid = 1;
        if (data_in) next_state = D11;
        else next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end


endmodule
