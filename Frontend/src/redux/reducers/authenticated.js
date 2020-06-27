import {type as logIn} from '../actions/isAuthenticated'
import {type as logOut} from '../actions/isLogOut'


const user = JSON.parse(localStorage.getItem('userInfo'));

const defaultState = user? {loggedIn: true, user} : {};

function reducer(state = defaultState, {type, payload}){
    switch(type){
        case logIn:
        if(!payload){
            return state;    
        }
        
        return {
            loggedIn: true,
            user: payload
        };

        case logOut:
            return payload;
                
        default: 
            return state;
    }    
}

export default reducer;