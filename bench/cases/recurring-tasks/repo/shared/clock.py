from datetime import date


# Returns today's date, kept in one place so tests can replace it.
def today():
    return date.today()
