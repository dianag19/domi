import React, { Component } from 'react'
import '../App.css';
import Footer from '../components/footer'
import { connect } from 'react-redux'
import { withRouter } from 'react-router-dom'
//componente: Formulario de usuario y conductor
import FormUser from '../components/formUser'
import FormDriver from '../components/FormDriver'


class Signin extends Component {

    constructor(props){
        super(props);
        this.state = {text:''}
        this.onChanged = this.onChanged.bind(this);
        this.customForm = this.customForm.bind(this);
        
    }

    onChanged(event){
        let textR = event.target.value;
        this.setState({
        text: textR.replace(/[^0-9]/g, '')
        });
    }


    render(){
        return(
            <div className="App">
                {this.customForm(this.props.role)}
                <Footer></Footer>
            </div>
        );    
    }


    customForm(role) {
        if (role === 'Usuario') {
            return (
                <FormUser/>
            );
        }else{
            return(
                <FormDriver/>
            );
        }
    }



}


const mapStateToProps = state => ({
    ...state,
    authenticated: state.authenticated
});

export default withRouter(connect(mapStateToProps)(Signin));
