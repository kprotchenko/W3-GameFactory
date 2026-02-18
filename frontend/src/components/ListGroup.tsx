import {useState} from "react";
interface Props {
    items: string[];
    header: string;
    onSelect: (item: string) => void;
}
function ListGroup({items, header, onSelect}: Props) {
    const [selectedIndex, setSelectedIndex] = useState(-1)
    const getMessage = () => {
        return items.length === 0 ? <p>No item found</p> : null;
    };

    // Event handler
    return (
        <>
            <h1>{header}</h1>
            {getMessage()}
            {items.length === 0 && <p>No item found</p>}
            <ul className="list-group">
                {items.map((item, index) => (
                    <li
                        key={item}
                        className={selectedIndex === index
                            ? 'list-group-item active'
                            : 'list-group-item'}
                        onClick={() => {
                            setSelectedIndex(index);
                            onSelect(item);
                        }}
                    >
                        {item}
                    </li>
                ))}
            </ul>
        </>
    );
}

export default ListGroup;