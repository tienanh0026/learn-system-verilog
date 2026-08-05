// Extend your priority arbiter — instead of fixed priority (req[0] always wins), 
// design a round-robin arbiter: whichever input won last time gets lowest priority next time, 
// so no single requester can permanently starve the others. 
// This needs internal state (sequential logic) to remember who won last.

module round_robin_arbiter #(
    parameter int WIDTH = 4
) (
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] req,
    output logic [WIDTH-1:0] grant
);

  logic [WIDTH-1:0] rotated_req, rotated_grant;
  logic [$clog2(WIDTH)-1:0] last_grant = 0;  // stores index of last winner

  // 1. rotate req based on last_grant
  // 2. instantiate priority_arbiter on rotated_req -> rotated_grant
  // 3. rotate rotated_grant BACK to get final grant
  // 4. always_ff: update last_grant based on grant (only when someone actually won)

  //   assign rotated_req = (req << last_grant + 1) | (req >> (WIDTH - last_grant + 1));

  logic [2*WIDTH-1:0] req_doubled;
  assign req_doubled = {req, req};
  assign rotated_req = req_doubled[(last_grant+1)+:WIDTH];

  always_comb begin
    rotated_grant = 4'b0000;
    for (int i = 0; i < WIDTH; i = i + 1) begin
      if (rotated_req[i] && rotated_grant == 0) begin
        rotated_grant[i] = 1;
      end
    end
  end

  //   assign grant = (rotated_grant >> last_grant + 1) | (rotated_grant << (WIDTH - last_grant + 1));

  logic [2*WIDTH-1:0] grant_doubled;
  assign grant_doubled = {rotated_grant, rotated_grant};
  assign grant = grant_doubled[(WIDTH-(last_grant+1))+:WIDTH];

  logic found = 1'b0;

  always_ff @(posedge clk) begin
    if (rst) begin
      last_grant <= 0;
    end else if (grant) begin
      found = 0;
      for (int i = 0; i < WIDTH; i++) begin
        if (grant[i] && ~found) begin
          found = 1;
          last_grant <= i;
        end
      end
    end
  end
endmodule
