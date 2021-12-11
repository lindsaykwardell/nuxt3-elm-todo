import type { IncomingMessage, OutgoingMessage } from "http";
import { useBody } from "h3";
import Prisma from "@prisma/client";

type Todo = {
  id: number;
  title: string;
  completed: boolean;
};

const prisma = new Prisma.PrismaClient();

export default async (
  req: IncomingMessage & { originalUrl: string },
  res: OutgoingMessage
) => {
  switch (req.method) {
    case "GET":
      if (req.originalUrl === "/api/todo") {
        return prisma.todo.findMany();
      } else {
        const id = getTodoId(req);
        return prisma.todo.findFirst({ where: { id } });
      }
    case "POST":
      const postBody = await useBody<Todo>(req);
      return prisma.todo.create({ data: postBody });
    case "PUT":
      const input = await useBody<Todo>(req);
      const todo = await prisma.todo.findFirst({
        where: { id: getTodoId(req) },
      });
      if (!todo) {
        return;
      }
      return prisma.todo.update({
        where: { id: getTodoId(req) },
        data: input,
      });
    case "DELETE":
      if (req.originalUrl === "/api/todo") {
        req.statusCode = 404;
        return;
      }
      const id = getTodoId(req);
      await prisma.todo.delete({ where: { id } });
      return { deleted: true };
    default:
      req.statusCode = 404;
      res.end();
  }
};

function getTodoId(req: IncomingMessage & { originalUrl: string }) {
  return Number(req.originalUrl.split("/")[3]);
}
