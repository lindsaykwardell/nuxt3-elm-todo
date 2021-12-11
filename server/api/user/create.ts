import type { IncomingMessage, OutgoingMessage } from "http";
import { useBody } from "h3";
import pkg from "@prisma/client";

const prisma = new pkg.PrismaClient();

export default async (
  req: IncomingMessage & { originalUrl: string },
  res: OutgoingMessage
) => {
  const body = await useBody(req);

  const result = await prisma.user.create({
    data: {
      ...body,
    },
  });

  return result;
};
