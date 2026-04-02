# Learning API Reference

Base URL:

```text
http://localhost:7000
```

If a route is marked `Protected`, the frontend should send:

```http
Authorization: Bearer <jwt-token>
```

## Auth Routes

### Signup

```http
POST /api/user/signup
```

Body:

```json
{
  "username": "adi",
  "email": "adi@example.com",
  "password": "secret123"
}
```

### Login

```http
POST /api/user/login
```

Body:

```json
{
  "email": "adi@example.com",
  "password": "secret123"
}
```

Returns:
- `token`
- `user`

### Profile

Protected:

```http
GET /api/user/profile
```

## Learning Routes

### Get All Courses

```http
GET /api/learning/courses
```

Use this to show the course selection screen.

### Get Course Map

```http
GET /api/learning/courses/:courseId/map
```

Examples:

```http
GET /api/learning/courses/c-programming/map
GET /api/learning/courses/6873b2158762afd0e7bb5d74/map
```

Use this to build the Duolingo-style path.

Optional:
- send Bearer token if you want progress flags for the logged-in user

### Get Quiz Questions

```http
GET /api/learning/quizzes/:quizId/questions
```

Example:

```http
GET /api/learning/quizzes/6873b2158762afd0e7bb5d74/questions
```

Use this when a user taps a quiz node.

### Submit Quiz Answers

Protected:

```http
POST /api/learning/quizzes/:quizId/submit
```

Body:

```json
{
  "answers": [
    {
      "questionId": "6873b2158762afd0e7bb5d75",
      "selectedAnswer": "while"
    },
    {
      "questionId": "6873b2158762afd0e7bb5d76",
      "selectedAnswer": "Condition"
    }
  ]
}
```

Use this after the quiz ends to store progress.

### Get Revision Questions For A Subtopic

Protected:

```http
GET /api/learning/subtopics/:subtopicId/revision
```

Use this after finishing a subtopic to fetch incorrect questions for revision.

## Frontend Flow

### Home / Course Select

Call:

```http
GET /api/learning/courses
```

### Path Screen

Call:

```http
GET /api/learning/courses/:courseId/map
```

Each chapter, subtopic, and quiz node in the response already contains IDs that Flutter should keep with the UI widgets.

### Quiz Screen

Call:

```http
GET /api/learning/quizzes/:quizId/questions
```

Frontend can show one question card at a time from the returned `questions` array.

### After Quiz Completion

Call:

```http
POST /api/learning/quizzes/:quizId/submit
```

### Revision Screen

Call:

```http
GET /api/learning/subtopics/:subtopicId/revision
```

## Example Flutter Mapping

When Flutter receives the course map:

- chapter node uses `chapter.id`
- subtopic circle uses `subtopic.id`
- opening a quiz uses `quiz.id`

So the frontend does not guess which circle is which.
It uses the IDs already returned by the backend.
