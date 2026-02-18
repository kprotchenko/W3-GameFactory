
interface Props {
    children: string;
    onClick?: () => void;
    type?: 'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'info' | 'light' | 'dark' | 'link';
}
export const Button = ({ children, type = 'primary', onClick }: Props) => {
    return (
        <button type="button" className={'btn btn-'+type} onClick={onClick}>{children}</button>
    )
}

export default Button
