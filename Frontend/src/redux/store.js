import { createStore, combineReducers} from 'redux'
import activarLogin from './reducers/activarLogin'
import authenticated from './reducers/authenticated'
import showInfo from './reducers/showInfo'

const reducer = combineReducers({
    activarLogin,
    authenticated,
    showInfo
});

const store = createStore(reducer);

export default store;