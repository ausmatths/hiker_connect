.PHONY: coverage coverage-html

coverage:
	flutter test --coverage

coverage-html: coverage
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html  # For macOS
	# xdg-open coverage/html/index.html  # For Linux
	# start coverage/html/index.html     # For Windows