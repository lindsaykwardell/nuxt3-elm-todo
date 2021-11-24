export type Todo = {
  id: number;
  title: string;
  completed: boolean;
};

const db: { todos: Todo[] } = {
  todos: [{ id: 1, title: "This is a todo", completed: false }],
};

export default db;
