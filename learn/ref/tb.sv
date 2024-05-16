`timescale 1ns / 1ps

module SISO_SR_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period in ns
    
    // Inputs
    reg clk;
    reg clear;
    reg SI;
    
    // Outputs
    wire SO;
    
    // Instantiate the unit under test (UUT)
    SISO_SR UUT (
        .clk(clk),
        .clear(clear),
        .SI(SI),
        .SO(SO)
    );
    
    // Clock generation
    always #((CLK_PERIOD / 2)) clk = ~clk;
    
    initial begin
        // Initialize inputs
        clear = 1'b1;
        SI = 1'b0;
        
        // Wait for a few clock cycles
        #20;
        
        // Release clear
        clear = 1'b0;
        
        // Apply test vectors
        SI = 1'b1; // You can change SI here to test different inputs
        
        // Monitor outputs
        $monitor("Time=%0t, SI=%b, SO=%b", $time, SI, SO);
        
        // Run for a few clock cycles
        #100;
        
        // End simulation
        $finish;
    end
    
endmodule
