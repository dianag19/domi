export const type = 'isAuthenticated';


const isAuthenticated = (user) => {
    localStorage.setItem('userInfo',JSON.stringify(user));
    return {type, payload: user};
};

export default isAuthenticated;