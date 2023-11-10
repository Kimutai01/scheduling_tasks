defmodule SchedulingTasks.EmailScheduler do
  alias SchedulingTasks.Accounts.UserNotifier
  def send_emails do
    # Logic to send emails
    IO.puts "Sending emails..."
    UserNotifier.deliver("kiprotichkimutai01@gmail.com", "Hello", "Hello from Elixir")
  end
end
