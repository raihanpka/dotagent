package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"sync"
)

var (
	errTaken   = errors.New("email already registered")
	errInvalid = errors.New("invalid email or password")
)

type user struct {
	id, email, hash string
}

type service struct {
	mu     sync.Mutex
	users  map[string]*user  // by email
	tokens map[string]string // token -> user id
}

func newService() *service {
	return &service{users: map[string]*user{}, tokens: map[string]string{}}
}

func hash(pw string) string {
	sum := sha256.Sum256([]byte(pw))
	return hex.EncodeToString(sum[:])
}

func randomID() string {
	b := make([]byte, 12)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func (s *service) signup(email, pw string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.users[email]; ok {
		return "", errTaken
	}
	u := &user{id: randomID(), email: email, hash: hash(pw)}
	s.users[email] = u
	return s.issue(u.id), nil
}

func (s *service) login(email, pw string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	u, ok := s.users[email]
	if !ok || u.hash != hash(pw) {
		return "", errInvalid
	}
	return s.issue(u.id), nil
}

// issue must be called with s.mu held.
func (s *service) issue(userID string) string {
	t := randomID()
	s.tokens[t] = userID
	return t
}

func (s *service) userForToken(t string) (string, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	id, ok := s.tokens[t]
	return id, ok
}
