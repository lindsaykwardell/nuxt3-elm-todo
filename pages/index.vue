<template>
  <Counter :todos="todos" />
</template>

<script setup lang="ts">
// @ts-ignore
import { Elm } from "../src/Main.elm";
import type { Todo } from "../server/db";
import elmBridge from "elm-vue-bridge";

const Counter = elmBridge(Elm, {
  name: "Counter",
  props: {
    todos: {
      type: Array,
      default: () => [],
    },
  },
});

const { data: todos } = await useFetch<"/api/todo", Todo[]>("/api/todo");
</script>
