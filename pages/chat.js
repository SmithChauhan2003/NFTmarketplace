import React from "react";
import { useChatStore } from "../lib/chatStore";
import Chat from "../components/Chat/Chat";
import Details from "../components/Chat/Details";
import List from "../components/List/List";
import styles from "../styles/chat.module.css";

const ChatPage = () => {
  const { chatId } = useChatStore();
  return (
    <div className={styles.body}>
      <div className={styles.container}>
        <List />
        {chatId && <Chat />}
        {chatId && <Details />}
      </div>
    </div>
  );
};

export default ChatPage;
