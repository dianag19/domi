import {type as activarLoginType} from '../actions/loginForm'
const defaultState = false;

function reducer(state = defaultState, {type, payload}){
    switch(type){
        case activarLoginType:
        if(!payload){
            return false;    
        }
        
        return payload;

        default: 
            return false;
    }    
}

export default reducer;



