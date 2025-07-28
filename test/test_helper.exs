# test/test_helper.exs
Application.ensure_all_started(:minidote)

ExUnit.start()

TestSetup.init()
ExUnit.start()
