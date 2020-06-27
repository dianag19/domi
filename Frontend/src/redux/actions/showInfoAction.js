export const type = 'showInfoAction';

const showInfoAction = (flag,res) => {
    if(flag){
        return( 
        {
            type,
            payload: {
                flag,
                res
                     }
        }); 
    }else{
        return {
            type,
            payload: {
                flag,
                res: {}    
            }    
        }    
    }
};

export default showInfoAction; 