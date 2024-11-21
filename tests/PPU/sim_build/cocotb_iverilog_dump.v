module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/ppu.fst");
    $dumpvars(0, ppu);
end
endmodule
