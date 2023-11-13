defmodule SchedulingTasks.UserPhoneNumber do
  def format_phone_number(phone_number) do
    cond do
      String.starts_with?(phone_number, "254") -> phone_number
      String.starts_with?(phone_number, "0") -> "254" <> String.slice(phone_number, 1..-1)
      String.starts_with?(phone_number, "+254") -> String.slice(phone_number, 1..-1)
      true -> "Unknown format"
    end
  end
end
