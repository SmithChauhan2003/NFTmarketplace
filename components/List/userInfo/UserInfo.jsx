import styles from "./userInfo.module.css";
import { useUserStore } from "../../../lib/userStore";
import Image from "next/image";
import images from "../../../img";

const Userinfo = () => {
  const { currentUser } = useUserStore();

  return (
    <div className={styles.userInfo}>
      <div className={styles.user}>
        <img
          src={currentUser?.avatar || "./avatar.png"}
          alt=""
          className={styles.userImg}
        />
        <h2 className={styles.userName}>{currentUser?.username}</h2>
      </div>
      <div className={styles.icons}>
        <Image src={images.phone} alt="" height="20px" width="20px" />
        <Image src={images.video} alt="" height="24px" width="24px" />
        <Image src={images.info} alt="" height="20px" width="20px" />
      </div>
    </div>
  );
};

export default Userinfo;
