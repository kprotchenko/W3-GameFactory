import {type ReactNode} from "react";

interface Props {
    children: ReactNode;
    onClose: () => void;
}

export const Alert = ({ children, onClose }: Props) => {
    // const [showAlert, setShowAlert] = useState(true)
    // <div className={showAlert ? "alert alert-primary alert-dismissible show": "alert alert-primary alert-dismissible fade"} role="alert"><
    return (
        <>
            <div className="alert alert-primary alert-dismissible show fade"
                 role="alert">
                <div>{children}</div>
                <button type="button"
                        className="btn-close"
                        data-bs-dismiss="alert"
                        aria-label="Close"
                        onClick={() => {
                            // setShowAlert(false);
                            onClose();
                        }}
                ></button>
            </div>

        </>
    )
}

export default Alert