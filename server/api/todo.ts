import type { IncomingMessage, OutgoingMessage } from "http";
import { useBody } from "h3";
import db, { Todo } from "../db";

export default async (
  req: IncomingMessage & { originalUrl: string },
  res: OutgoingMessage
) => {
  switch (req.method) {
    case "GET":
      if (req.originalUrl === "/api/todo") {
        return db.todos;
      } else {
        const id = getTodoId(req);
        return db.todos.find((todo) => todo.id === id);
      }
    case "POST":
      const todo = await useBody<Todo>(req);
      todo.id = db.todos.length + 1;
      db.todos.push(todo);
      return todo;
    case "PUT":
      const input = await useBody<Todo>(req);
      db.todos = db.todos.map((todo) => (todo.id === input.id ? input : todo));
      return input;
    case "DELETE":
      if (req.originalUrl === "/api/todo") {
        req.statusCode = 404;
        return;
      }
      const id = getTodoId(req);
      db.todos = db.todos.filter((todo) => todo.id !== id);
      return { deleted: true };
    default:
      req.statusCode = 404;
      res.end();
  }
};

function getTodoId(req: IncomingMessage & { originalUrl: string }) {
  return Number(req.originalUrl.split("/")[3]);
}
