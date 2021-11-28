require 'tmt/commands/tasty_dxfeed'

RSpec.describe Tmt::Commands::TastyDxfeed do
  xit "executes `tasty_dxfeed` command successfully" do
    output = StringIO.new
    options = {}
    command = Tmt::Commands::TastyDxfeed.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
