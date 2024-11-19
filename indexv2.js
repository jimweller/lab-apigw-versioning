exports.handler = async (event) => {
    if (!event.side) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: "Missing 'side' parameter" }),
        };
    }
    return {
        statusCode: 200,
        body: JSON.stringify({ sith: "Darth Vader" }),
    };
};
