require 'tmt/commands/positions'

RSpec.describe Tmt::Commands::Positions do
  xit "executes `positions` command successfully" do
    output = StringIO.new
    options = {}
    command = Tmt::Commands::Positions.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
