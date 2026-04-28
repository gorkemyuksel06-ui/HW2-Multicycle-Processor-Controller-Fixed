module datapath(
    input  logic        clk, reset,
    input  logic        pcwrite,
    input  logic        adrsrc,
    input  logic        irwrite,
    input  logic        regwrite,
    input  logic [1:0]  resultsrc,
    input  logic [1:0]  alusrca,
    input  logic [1:0]  alusrcb,
    input  logic [1:0]  immsrc,
    input  logic [2:0]  alucontrol,
    output logic [6:0]  op,
    output logic [2:0]  funct3,
    output logic        funct7b5,
    output logic        zero,
    output logic [31:0] adr, writedata,
    input  logic [31:0] readdata,
    output logic [31:0] result
);

    logic [31:0] pc, oldpc;
    logic [31:0] instr;
    logic [31:0] data;
    logic [31:0] a;
    logic [31:0] aluresult, aluout;
    logic [31:0] immext;
    logic [31:0] rd1, rd2;
    logic [31:0] srca, srcb;

    assign op       = instr[6:0];
    assign funct3   = instr[14:12];
    assign funct7b5 = instr[30];

    always_ff @(posedge clk or posedge reset)
        if (reset) pc <= 32'b0;
        else if (pcwrite) pc <= result;

    always_ff @(posedge clk or posedge reset)
        if (reset) 	  oldpc <= 32'b0;
        else if (irwrite) oldpc <= pc;

    assign adr = adrsrc ? aluout : pc;

    always_ff @(posedge clk or posedge reset)
        if (reset)        instr <= 32'b0;
        else if (irwrite) instr <= readdata;

    always_ff @(posedge clk or posedge reset)
        if (reset) data <= 32'b0;
        else       data <= readdata;

    regfile rf(
        .clk (clk), .we3 (regwrite),
        .a1  (instr[19:15]), .a2  (instr[24:20]), .a3  (instr[11:7]),
        .wd3 (result), .rd1 (rd1), .rd2 (rd2)
    );

    always_ff @(posedge clk or posedge reset)
        if (reset) a <= 32'b0;
        else       a <= rd1;

    always_ff @(posedge clk or posedge reset)
        if (reset) writedata <= 32'b0;
        else       writedata <= rd2;

    extend ext(.instr(instr), .immsrc(immsrc), .immext(immext));

    always_comb
        case (alusrca)
            2'b00:   srca = pc;
            2'b01:   srca = oldpc;
            2'b10:   srca = a;
            default: srca = pc;
        endcase

    always_comb
        case (alusrcb)
            2'b00:   srcb = writedata;
            2'b01:   srcb = immext;
            2'b10:   srcb = 32'd4;
            default: srcb = writedata;
        endcase

    alu alu(.a(srca), .b(srcb), .alucontrol(alucontrol), .result(aluresult), .zero(zero));

    always_ff @(posedge clk or posedge reset)
        if (reset) aluout <= 32'b0;
        else       aluout <= aluresult;

    always_comb
        case (resultsrc)
            2'b00:   result = aluout;
            2'b01:   result = data;
            2'b10:   result = aluresult;
            default: result = aluout;
        endcase

endmodule

module regfile(
    input  logic        clk, we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf [31:0];
    always_ff @(posedge clk)
        if (we3) rf[a3] <= wd3;
    assign rd1 = (a1 != 5'b0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 5'b0) ? rf[a2] : 32'b0;
endmodule

module extend(
    input  logic [31:0] instr,
    input  logic [1:0]  immsrc,
    output logic [31:0] immext
);
    always_comb
        case (immsrc)
            2'b00: immext = {{20{instr[31]}}, instr[31:20]};
            2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: immext = 32'b0;
        endcase
endmodule

module alu(
    input  logic [31:0] a, b,
    input  logic [2:0]  alucontrol,
    output logic [31:0] result,
    output logic        zero
);
    logic [31:0] condinvb, sum;
    assign condinvb = alucontrol[0] ? ~b : b;
    assign sum      = a + condinvb + {31'b0, alucontrol[0]};
    always_comb
        case (alucontrol)
            3'b000: result = sum;
            3'b001: result = sum;
            3'b010: result = a & b;
            3'b011: result = a | b;
            3'b101: result = {31'b0, sum[31]};
            default: result = 32'b0;
        endcase
    assign zero = (result == 32'b0);
endmodule
