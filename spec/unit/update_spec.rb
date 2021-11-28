require 'tmt/commands/update'

RSpec.describe Tmt::Commands::Update do
  xit "executes `update` command successfully" do
    output = StringIO.new
    id = nil
    mark = nil
    options = {}
    command = Tmt::Commands::Update.new(id, mark, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
