module CrystalOscillator;
  reg clock;

  task Clock;
    begin
      clock = 0;
      #20;
      clock = 1;
      #20;
    end
  endtask

endmodule
