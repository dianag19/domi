export const type = 'isLogOut';


const isLogOut = () => {
    localStorage.removeItem('userInfo');
    return {type,
            payload: {}};
};

export default isLogOut;