
module testbench(cam_itf itf);
import cam_types::*;

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

task write(input key_t key, input val_t val);
    itf.key <= key;
    itf.val_i <= val;
    itf.rw_n <= 1'b0;
    itf.valid_i <= 1'b1;
    @(tb_clk);
    itf.valid_i <= 1'b0;
    @(tb_clk);
endtask

task read(input key_t key, output val_t val);
    itf.key <= key;
    itf.rw_n <= 1'b1;
    itf.valid_i <= 1'b1;
    @(tb_clk);
    val <= itf.val_o;
    itf.valid_i <= 1'b0;
    @(tb_clk);
endtask

task rwtest();
    @(tb_clk);
    for (int i = 0 ; i < 8 ; i++) begin
        //write
        itf.key <= i;
        itf.val_i <= i;
        itf.rw_n <= 1'b0;
        itf.valid_i <= 1'b1;
        @(tb_clk);
        //read
        itf.rw_n <= 1'b1;
        @(tb_clk);
        assert (itf.val_o == i) else  begin
    	    itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, i);
        end
    end
    itf.valid_i <= 1'b0;
    @(tb_clk);
endtask : rwtest

task testevict();
    @(tb_clk);
    itf.rw_n <= 1'b0;
    itf.valid_i <= 1'b1;
    for (int i = 0 ; i < 8 ; i++) begin
        //rewrite every key and value pairs
        itf.key <= i+8;
        itf.val_i <= i+10;
        @(tb_clk);
    end
    itf.valid_i <= 1'b0;
    @(tb_clk);
endtask : testevict

task consecutive();
    @(tb_clk);
    //first write
    itf.rw_n <= 1'b0;
    itf.valid_i <= 1'b1;
    itf.key <= 8;
    itf.val_i <= 0;
    @(tb_clk);
    //second write
    itf.val_i <= 1;
    @(tb_clk);
    //third write
    itf.val_i <= 2;
    @(tb_clk);
    itf.valid_i <= 1'b0;
    @(tb_clk);
endtask : consecutive

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
    rwtest();
    testevict();
    consecutive();

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
