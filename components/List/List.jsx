import ChatList from "./chatList/ChatList";
import styles from "./list.module.css";
import Userinfo from "./userInfo/Userinfo";

const List = () => {
  return (
    <div className={styles.list}>
      <Userinfo />
      <ChatList />
    </div>
  );
};

export default List;
