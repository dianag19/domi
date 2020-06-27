export const type = 'loginForm';

const loginForm = (bool) => ({
    type,
    payload: bool 
});

export default loginForm;