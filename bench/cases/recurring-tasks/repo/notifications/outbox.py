_OUTBOX = {}


# Stores a message for a user, standing in for a real push or email channel.
def notify(user, message):
    _OUTBOX.setdefault(user, []).append(message)


# Returns the messages stored for a user, oldest first.
def outbox_for(user):
    return list(_OUTBOX.get(user, []))


# Empties the outbox, used by tests.
def reset():
    _OUTBOX.clear()
