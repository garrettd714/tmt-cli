RSpec.describe "`tmt update` command", type: :cli do
  it "executes `tmt help update` command successfully" do
    output = `tmt help update`
    expected_output = <<-OUT
Usage:
  tmt update id

Options:
  -h, [--help], [--no-help]  # Update a position
      [--mark=N]             # Update the trade mark manually
      [--ticker-price=N]     # Update the ticker price manually
      [--note=NOTE]          # Append a note

Update position, -u id [--edit id | -e id] [--mark= --ticker_price= --note=]
    OUT

    expect(output).to include(expected_output)
  end
end
