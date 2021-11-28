require 'tmt/commands/tasty_refresh'

RSpec.describe Tmt::Commands::TastyRefresh do
  xit "executes `tasty_refresh` command successfully" do
    output = StringIO.new
    options = {}
    command = Tmt::Commands::TastyRefresh.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
